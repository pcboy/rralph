module Rralph
  class FileUpdater
    def initialize(todo_path: "todo.md", learnings_path: "learnings.md")
      @todo_path = todo_path
      @learnings_path = learnings_path
    end

    def mark_task_completed(task_index)
      content = File.read(@todo_path)
      lines = content.lines

      line = lines[task_index]
      if line
        updated_line = line.gsub(/^([-*]) \[ \]/, '\1 [x]')
        lines[task_index] = updated_line
        File.write(@todo_path, lines.join)
      end
    end

    def append_learnings(new_learnings)
      return if new_learnings.empty?

      existing_content = File.exist?(@learnings_path) ? File.read(@learnings_path) : ""
      existing_learnings = existing_content.lines.map(&:strip).reject(&:empty?)

      unique_learnings = new_learnings.reject do |learning|
        existing_learnings.any? { |existing| existing.include?(learning) || learning.include?(existing) }
      end

      return if unique_learnings.empty?

      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      new_section = "\n\n## Learnings - #{timestamp}\n\n"
      unique_learnings.each do |learning|
        new_section += "- #{learning}\n"
      end

      File.write(@learnings_path, existing_content.rstrip + new_section + "\n")
    end

    def todo_empty?
      return true unless File.exist?(@todo_path)

      content = File.read(@todo_path)
      content.lines.none? { |line| line.match?(/^[-*] \[ \]/i) }
    end
  end
end
