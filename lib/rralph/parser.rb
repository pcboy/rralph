module Rralph
  class Parser
    attr_reader :plan_content, :learnings_content, :todo_content

    def initialize(plan_path: "plan.md", learnings_path: "learnings.md", todo_path: "todo.md")
      @plan_path = plan_path
      @learnings_path = learnings_path
      @todo_path = todo_path
    end

    def load_files
      raise FileNotFound, "plan.md not found" unless File.exist?(@plan_path)

      @plan_content = File.read(@plan_path)
      @learnings_content = File.exist?(@learnings_path) ? File.read(@learnings_path) : ""
      @todo_content = File.exist?(@todo_path) ? File.read(@todo_path) : ""
    end

    def pending_tasks
      return [] unless @todo_content

      @todo_content.lines.map.with_index do |line, index|
        stripped = line.strip
        next unless stripped.start_with?("- [ ]") || stripped.start_with?("* [ ]")

        task_text = stripped.sub(/^[-*] \[ \] /, "").strip
        { index: index, line: line, text: task_text, raw: stripped }
      end.compact
    end

    def completed_tasks
      return [] unless @todo_content

      @todo_content.lines.map.with_index do |line, index|
        stripped = line.strip
        next unless stripped.start_with?("- [x]") || stripped.start_with?("* [x]")

        task_text = stripped.sub(/^[-*] \[x\] /i, "").strip
        { index: index, line: line, text: task_text, raw: stripped }
      end.compact
    end

    def all_tasks
      return [] unless @todo_content

      @todo_content.lines.map.with_index do |line, index|
        stripped = line.strip
        next unless stripped.match?(/^[-*] \[[ x]\]/i)

        completed = stripped.match?(/^[-*] \[x\]/i)
        task_text = stripped.sub(/^[-*] \[[ x]\] /i, "").strip
        { index: index, line: line, text: task_text, raw: stripped, completed: completed }
      end.compact
    end

    def has_pending_tasks?
      pending_tasks.any?
    end

    def failure_detected?(response)
      response.match?(/\bFAILURE\b/i)
    end

    def extract_learnings(response)
      learnings = []

      # Match various learning patterns like:
      # "Learning: xyz", "**Learning to add:** xyz", "- Learning: xyz", etc.
      response.lines.each do |line|
        if match = line.match(/(?:^|\s)(?:\*\*)?(?:Learning|Insight|Note|Tip|Discovered|Found|Realized)[\s*]*[:\s]*(?:to add)?[:\s]*(.+?)(?:\*\*)?(?:\s*$)/i)
          learning = match[1].strip
          learning = learning.gsub(/^\*\*|\*\*$/, "").strip
          learnings << learning unless learning.empty?
        end
      end

      # Also extract from ## Learnings sections
      if response.match?(/##?\s+Learnings/i)
        section = response.split(/##?\s+Learnings/i)[1]
        section = section.split(/##?\s+/)[0] if section.match?(/##?\s+/)
        section.lines.each do |line|
          stripped = line.strip
          next if stripped.empty?
          stripped = stripped.sub(/^[-*]\s*/, "")
          learnings << stripped unless stripped.empty?
        end
      end

      learnings.uniq
    end

    def build_prompt(current_task: nil)
      <<~PROMPT
        You are in an iterative development loop. There is a todo list with tasks.
        
        YOUR CURRENT TASK (the first unchecked item in todo.md):
        > #{current_task}
        
        INSTRUCTIONS - Follow these steps in order:
        1. Implement ONLY the task shown above
        2. Write a unit test for it
        3. Run the test
        4. Respond with exactly one of:
           - "DONE" if the task is complete and test passes
           - "FAILURE" if the test fails after your best effort
        5. Optionally add learnings as: "Learning: <insight>"
        
        IMPORTANT RULES:
        - Work on ONE task only - the one shown above
        - Do NOT implement other tasks from the todo list
        - Do NOT mark tasks as done yourself
        - After you respond "DONE", the system will mark this task complete
        - Then you will receive the next task
        
        --- plan.md (context) ---
        #{@plan_content}

        --- learnings.md (prior knowledge) ---
        #{@learnings_content}

        --- todo.md (full list - work on first unchecked only) ---
        #{@todo_content}
      PROMPT
    end
  end
end
