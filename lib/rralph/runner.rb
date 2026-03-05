require 'json'
require 'open3'
require 'amazing_print'
module Rralph
  class Runner
    attr_reader :cycle_count, :failure_count, :max_failures

    def initialize(
      max_failures: 3,
      ai_command: 'qwen-code -y -s -o stream-json',
      watch: false,
      plan_path: 'plan.md',
      learnings_path: 'learnings.md',
      todo_path: 'todo.md',
      skip_commit: false,
      verbose: false
    )
      @max_failures = max_failures
      @ai_command = ai_command
      @watch = watch
      @plan_path = plan_path
      @learnings_path = learnings_path
      @todo_path = todo_path
      @skip_commit = skip_commit
      @verbose = verbose

      @cycle_count = 0
      @failure_count = 0

      @parser = Parser.new(
        plan_path: @plan_path,
        learnings_path: @learnings_path,
        todo_path: @todo_path
      )
      @file_updater = FileUpdater.new(
        todo_path: @todo_path,
        learnings_path: @learnings_path
      )
      @git = Git.new
    end

    def run
      log("Starting rralph with max_failures=#{@max_failures}, ai_command='#{@ai_command}'")

      raise GitError, 'Not in a git repository. Please initialize git first.' unless @git.in_git_repo?

      @parser.load_files

      if todo_empty_or_missing?
        log('todo.md is empty or missing. Generating todo list from plan...')
        generate_todo_from_plan
        return true
      end

      unless @parser.has_pending_tasks?
        log('All tasks completed! Well done!')
        return true
      end

      return run_watch_loop if @watch

      run_single_cycle
    end

    private

    def run_watch_loop
      loop do
        success = run_single_cycle
        break unless success
        break unless @parser.has_pending_tasks?
        break if @failure_count >= @max_failures
      end

      check_final_state
    end

    def run_single_cycle
      @cycle_count += 1

      @parser.load_files

      unless @parser.has_pending_tasks?
        log('All tasks completed! Well done!')
        return false
      end

      pending = @parser.pending_tasks
      current_task = pending.first

      log("Cycle #{@cycle_count}: Processing task: #{current_task[:text]}")

      prompt = @parser.build_prompt(current_task: current_task[:text])
      response = execute_ai_command(prompt)

      # Always save AI request/response to logs for debugging
      save_ai_log(prompt, response)

      if response.nil?
        @failure_count += 1
        log("❌ [Cycle #{@cycle_count}] AI command failed. Failures: #{@failure_count}/#{@max_failures}")
        return handle_failure
      end

      if @parser.failure_detected?(response)
        @failure_count += 1
        log("❌ [Cycle #{@cycle_count}] TASK_FAILURE detected. Failures: #{@failure_count}/#{@max_failures}")
        return handle_failure
      end

      unless @parser.task_completed?(response)
        @failure_count += 1
        log("❌ [Cycle #{@cycle_count}] Neither TASK_DONE nor TASK_FAILURE found. Failures: #{@failure_count}/#{@max_failures}")
        return handle_failure
      end

      @failure_count = 0
      log("✅ [Cycle #{@cycle_count}] Task completed. #{@failure_count} failures.")

      @file_updater.mark_task_completed(current_task[:index])

      new_learnings = @parser.extract_learnings(response)
      @file_updater.append_learnings(new_learnings) if new_learnings.any?

      if @skip_commit
        log("⏭️ [Cycle #{@cycle_count}] Skipping commit (skip_commit enabled)")
      else
        commit_message = "rralph: #{current_task[:text]} [cycle #{@cycle_count}]"
        sha = @git.commit_changes(commit_message)

        log("   Git commit: #{sha}") if sha
      end

      true
    end

    def handle_failure
      if @failure_count >= @max_failures
        log("Max failures reached (#{@failure_count}). Stopping to avoid infinite loops. Review learnings.md and todo.md.")
        exit 1
      end
      true
    end

    def check_final_state
      if @failure_count >= @max_failures
        exit 1
      elsif !@parser.has_pending_tasks?
        log('All tasks completed! Well done!')
        exit 0
      end
    end

    def execute_ai_command(prompt)
      full_response = ''

      begin
        log('Executing AI command...')

        cmd = @ai_command

        Open3.popen3(cmd) do |stdin, stdout, _stderr, wait_thr|
          # Write prompt to stdin and close
          stdin.write(prompt)
          stdin.close

          # Process stdout line by line for real-time streaming
          stdout.each_line do |line|
            event = JSON.parse(line)

            case event['type']
            when 'assistant'
              content = event.dig('message', 'content')
              content&.each do |item|
                case item['type']
                when 'thinking'
                  log("[Thinking] #{item['thinking']}") if @verbose
                when 'text'
                  text = item['text']
                  full_response += text
                  log("[text] #{text}") if @verbose
                when 'tool_use'
                  tool_name = item['name']
                  tool_input = item['input']
                  log("[tool_use] #{tool_name}: #{tool_input.to_json}") if @verbose
                end
              end
            when 'user'
              if @verbose
                content = event.dig('message', 'content')
                content&.each do |item|
                  if item['type'] == 'tool_result'
                    tool_name = item.dig('tool_use_id')&.split('_')&.first || 'tool'
                    result = item['content']
                    log("[#{tool_name}] #{result}")
                  elsif item['type'] == 'text'
                    log("[text] #{item['text']}")
                  end
                end
              end
            when 'result'
              duration = event['duration_ms']
              tokens = event.dig('usage', 'total_tokens')
              is_error = event['is_error']
              if is_error
                log('AI command failed')
              else
                log("Completed in #{duration}ms (#{tokens} tokens)")
              end
            else
              log("   [event: #{event['type']}]") if @verbose
            end
          rescue JSON::ParserError
            # Non-JSON output (e.g., plain text from AI) - still capture it
            full_response += line
            log("   #{line.chomp}") if @verbose
          end

          log("   Command exit status: #{wait_thr.value.exitstatus}")
        end

        full_response.strip.empty? ? nil : full_response
      rescue Errno::ENOENT => e
        log("Error: AI command '#{@ai_command}' not found: #{e.message}")
        nil
      rescue StandardError => e
        log("Error executing AI command: #{e.message}")
        nil
      end
    end

    def save_ai_log(prompt, response)
      logs_dir = 'logs'
      Dir.mkdir(logs_dir) unless Dir.exist?(logs_dir)

      timestamp = Time.now.iso8601
      filename = "#{logs_dir}/cycle_#{@cycle_count}_#{timestamp}.md"

      # Extract just the current task for the header
      task_match = prompt.match(/YOUR CURRENT TASK.*?\n>\s*(.+?)\n/)
      task_text = task_match ? task_match[1].strip : 'Unknown'

      content = <<~LOG
        # Cycle #{@cycle_count} - #{timestamp}

        ## Current Task
        #{task_text}

        ## AI Response

        #{response || '(no response)'}
      LOG

      File.write(filename, content)
      log("   Log saved: #{filename}")
    end

    def log(message)
      warn(message)
    end

    def todo_empty_or_missing?
      return true unless File.exist?(@todo_path)

      content = File.read(@todo_path)
      content.strip.empty?
    end

    def generate_todo_from_plan
      prompt = build_todo_generation_prompt
      response = execute_ai_command(prompt)

      return log('❌ AI command failed when generating todo') unless response

      todo_items = extract_todo_items(response)
      return log('❌ Could not parse tasks from AI response') if todo_items.empty?

      save_todo_file(todo_items)
      handle_todo_commit(todo_items.size)
    end

    def build_todo_generation_prompt
      <<~PROMPT
        Based on the following plan, generate a todo list with actionable tasks.
        Format each task as a markdown checkbox like: - [ ] Task description
        Keep tasks specific and actionable.

        --- plan.md ---
        #{@parser.plan_content}
      PROMPT
    end

    def extract_todo_items(response)
      response.scan(/^- \[ \] .+$/).uniq
    end

    def save_todo_file(todo_items)
      todo_content = <<~TODO
        # Todo List

        #{todo_items.join("\n")}
      TODO

      File.write(@todo_path, todo_content)
    end

    def handle_todo_commit(task_count)
      if @skip_commit
        log("⏭️  Generated #{task_count} tasks (skip_commit enabled, no commit)")
      else
        commit_message = 'rralph: generated todo from plan.md'
        sha = @git.commit_changes(commit_message)
        log("✅ Generated #{task_count} tasks. Git commit: #{sha}") if sha
      end
    end
  end
end
