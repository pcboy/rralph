require "spec_helper"
require "rralph"
require "tmpdir"
require "fileutils"

RSpec.describe Rralph::Runner do
  let(:temp_dir) { Dir.mktmpdir }
  let(:plan_path) { File.join(temp_dir, "plan.md") }
  let(:learnings_path) { File.join(temp_dir, "learnings.md") }
  let(:todo_path) { File.join(temp_dir, "todo.md") }

  before do
    Dir.chdir(temp_dir) do
      `git init`
      File.write(plan_path, "Test plan")
      File.write(learnings_path, "")
      File.write(todo_path, "- [x] Task 1\n- [ ] Task 2")
      `git add .`
      `git commit -m "initial"`
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "skip_commit option" do
    it "does not call git commit when skip_commit is true" do
      runner = Rralph::Runner.new(
        skip_commit: true,
        plan_path: plan_path,
        learnings_path: learnings_path,
        todo_path: todo_path
      )

      allow(runner).to receive(:execute_ai_command).and_return("SUCCESS")
      allow_any_instance_of(Rralph::Git).to receive(:commit_changes).and_call_original

      expect_any_instance_of(Rralph::Git).not_to receive(:commit_changes)

      runner.run
    end

    it "calls git commit when skip_commit is false (default)" do
      runner = Rralph::Runner.new(
        skip_commit: false,
        plan_path: plan_path,
        learnings_path: learnings_path,
        todo_path: todo_path
      )

      allow(runner).to receive(:execute_ai_command).and_return("SUCCESS")
      allow_any_instance_of(Rralph::Git).to receive(:commit_changes).and_return("abc123")

      expect_any_instance_of(Rralph::Git).to receive(:commit_changes).once

      runner.run
    end

    it "logs skip message when skip_commit is enabled" do
      runner = Rralph::Runner.new(
        skip_commit: true,
        plan_path: plan_path,
        learnings_path: learnings_path,
        todo_path: todo_path
      )

      allow(runner).to receive(:execute_ai_command).and_return("SUCCESS")
      allow(runner).to receive(:log).and_call_original

      expect(runner).to receive(:log).with(/Skipping commit/)

      runner.run
    end
  end
end
