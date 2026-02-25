module Rralph
  class Runner
    attr_reader :cycle_count, :failure_count, :max_failures

    def initialize(
      max_failures: 3,
      ai_command: "qwen-code -y -s",
      watch: false,
      plan_path: "plan.md",
      learnings_path: "learnings.md",
      todo_path: "todo.md"
    )
      @max_failures = max_failures
      @ai_command = ai_command
      @watch = watch
      @plan_path = plan_path
      @learnings_path = learnings_path
      @todo_path = todo_path

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

      unless @git.in_git_repo?
        raise GitError, "Not in a git repository. Please initialize git first."
      end

      @parser.load_files

      if todo_empty_or_missing?
        log("todo.md is empty or missing. Generating todo list from plan...")
        generate_todo_from_plan
        return true
      end

      unless @parser.has_pending_tasks?
        log("All tasks completed! Well done!")
        return true
      end

      if @watch
        run_watch_loop
      else
        run_single_cycle
      end
    end

    private

    def run_watch_loop
      loop do
        success = run_single_cycle
        break unless success
        break unless @parser.has_pending_tasks?
        break if @failure_count >= @max_failures

        sleep 1
      end

      check_final_state
    end

    def run_single_cycle
      @cycle_count += 1

      @parser.load_files

      unless @parser.has_pending_tasks?
        log("All tasks completed! Well done!")
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
        log("❌ [Cycle #{@cycle_count}] FAILURE detected. Failures: #{@failure_count}/#{@max_failures}")
        return handle_failure
      end

      @failure_count = 0
      log("✅ [Cycle #{@cycle_count}] Task completed. #{@failure_count} failures.")

      @file_updater.mark_task_completed(current_task[:index])

      new_learnings = @parser.extract_learnings(response)
      @file_updater.append_learnings(new_learnings) if new_learnings.any?

      commit_message = "rralph: completed task and updated artifacts [cycle #{@cycle_count}]"
      sha = @git.commit_changes(commit_message)

      if sha
        log("   Git commit: #{sha}")
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
        log("All tasks completed! Well done!")
        exit 0
      end
    end

    def execute_ai_command(prompt)
      require "tempfile"

      # Write prompt to a temporary file
      prompt_file = Tempfile.new(["rralph_prompt", ".txt"])
      prompt_file.write(prompt)
      prompt_file.close

      # Read response from a temporary file  
      response_file = Tempfile.new(["rralph_response", ".txt"])
      response_file.close

      begin
        # Use bash -c with proper stdin redirection
        cmd = "bash -c #{@ai_command.shellescape} < #{prompt_file.path} > #{response_file.path} 2>&1"
        log("   Executing: #{@ai_command}")
        system(cmd)

        log("   Command exit status: #{$?.exitstatus}")
        
        response = File.read(response_file.path)
        response.strip.empty? ? nil : response
      ensure
        prompt_file.unlink
        response_file.unlink
      end
    rescue Errno::ENOENT => e
      log("Error: AI command '#{@ai_command}' not found: #{e.message}")
      nil
    rescue => e
      log("Error executing AI command: #{e.message}")
      nil
    end

    def save_ai_log(prompt, response)
      logs_dir = "logs"
      Dir.mkdir(logs_dir) unless Dir.exist?(logs_dir)

      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      filename = "#{logs_dir}/cycle_#{@cycle_count}_#{timestamp}.md"
      
      # Extract just the current task for the header
      task_match = prompt.match(/YOUR CURRENT TASK.*?>\s*(.+?)\n/)
      task_text = task_match ? task_match[1].strip : "Unknown"

      content = <<~LOG
        # Cycle #{@cycle_count} - #{timestamp}

        ## Current Task
        #{task_text}

        ## AI Response

        #{response || "(no response)"}
      LOG

      File.write(filename, content)
      log("   Log saved: #{filename}")
    end

    def log(message)
      $stderr.puts(message)
    end

    def todo_empty_or_missing?
      return true unless File.exist?(@todo_path)

      content = File.read(@todo_path)
      content.strip.empty? || !content.match?(/^- \[ \]/m)
    end

    def generate_todo_from_plan
      prompt = <<~PROMPT
        Based on the following plan, generate a todo list with actionable tasks.
        Format each task as a markdown checkbox like: - [ ] Task description
        Keep tasks specific and actionable.

        --- plan.md ---
        #{@parser.plan_content}
      PROMPT

      response = execute_ai_command(prompt)

      if response
        todo_items = response.scan(/^- \[ \] .+$/).uniq

        if todo_items.any?
          todo_content = "# Todo List\n\n" + todo_items.join("\n") + "\n"

          File.write(@todo_path, todo_content)

          commit_message = "rralph: generated todo from plan.md"
          sha = @git.commit_changes(commit_message)

          if sha
            log("✅ Generated #{todo_items.size} tasks. Git commit: #{sha}")
          end
        else
          log("❌ Could not parse tasks from AI response")
        end
      else
        log("❌ AI command failed when generating todo")
      end
    end
  end
end
