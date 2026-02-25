require "thor"
require_relative "runner"

module Rralph
  class CLI < Thor
    desc "start", "Run the rralph orchestrator"
    method_option :max_failures,
                  type: :numeric,
                  default: 3,
                  aliases: "-m",
                  desc: "Maximum allowed failures before stopping"
    method_option :ai_command,
                  type: :string,
                  default: "qwen-code -y -s",
                  aliases: "-a",
                  desc: "AI command to invoke"
    method_option :watch,
                  type: :boolean,
                  default: false,
                  aliases: "-w",
                  desc: "Run in continuous loop until completion or max failures"
    method_option :plan_path,
                  type: :string,
                  default: "plan.md",
                  aliases: "-p",
                  desc: "Path to plan.md file"
    method_option :learnings_path,
                  type: :string,
                  default: "learnings.md",
                  aliases: "-l",
                  desc: "Path to learnings.md file"
    method_option :todo_path,
                  type: :string,
                  default: "todo.md",
                  aliases: "-t",
                  desc: "Path to todo.md file"

    def start
      runner = Runner.new(
        max_failures: options[:max_failures],
        ai_command: options[:ai_command],
        watch: options[:watch],
        plan_path: options[:plan_path],
        learnings_path: options[:learnings_path],
        todo_path: options[:todo_path]
      )

      runner.run
    rescue Rralph::FileNotFound => e
      $stderr.puts "Error: #{e.message}"
      $stderr.puts "Please ensure plan.md, learnings.md, and todo.md exist in the current directory."
      exit 1
    rescue Rralph::GitError => e
      $stderr.puts "Git Error: #{e.message}"
      exit 1
    rescue => e
      $stderr.puts "Unexpected error: #{e.message}"
      $stderr.puts e.backtrace.first(5)
      exit 1
    end

    desc "version", "Show rralph version"
    def version
      puts "rralph v#{Rralph::VERSION}"
    end

    desc "stats", "Show progress statistics"
    method_option :plan_path,
                  type: :string,
                  default: "plan.md",
                  aliases: "-p"
    method_option :learnings_path,
                  type: :string,
                  default: "learnings.md",
                  aliases: "-l"
    method_option :todo_path,
                  type: :string,
                  default: "todo.md",
                  aliases: "-t"

    def stats
      parser = Parser.new(
        plan_path: options[:plan_path],
        learnings_path: options[:learnings_path],
        todo_path: options[:todo_path]
      )

      parser.load_files

      all_tasks = parser.all_tasks
      completed = parser.completed_tasks
      pending = parser.pending_tasks

      puts "Tasks: #{completed.size}/#{all_tasks.size} done"
      puts "Pending: #{pending.size}"
      puts "Learnings: #{parser.learnings_content.lines.size} lines"
    rescue Rralph::FileNotFound => e
      $stderr.puts "Error: #{e.message}"
      exit 1
    end

    default_task :start
  end
end
