require "spec_helper"
require "rralph"
require "tempfile"

RSpec.describe Rralph::FileUpdater do
  let(:todo_file) { Tempfile.new(["todo", ".md"]) }
  let(:learnings_file) { Tempfile.new(["learnings", ".md"]) }
  let(:todo_path) { todo_file.path }
  let(:learnings_path) { learnings_file.path }

  after do
    todo_file.close
    learnings_file.close
    todo_file.unlink
    learnings_file.unlink
  end

  describe "#mark_task_completed" do
    it "converts unchecked task to checked" do
      File.write(todo_path, "- [ ] Task 1\n- [ ] Task 2")
      updater = Rralph::FileUpdater.new(todo_path: todo_path, learnings_path: learnings_path)

      updater.mark_task_completed(0)

      content = File.read(todo_path)
      expect(content).to include("- [x] Task 1")
      expect(content).to include("- [ ] Task 2")
    end

    it "handles asterisk format" do
      File.write(todo_path, "* [ ] Task 1\n* [ ] Task 2")
      updater = Rralph::FileUpdater.new(todo_path: todo_path, learnings_path: learnings_path)

      updater.mark_task_completed(0)

      content = File.read(todo_path)
      expect(content).to include("* [x] Task 1")
    end
  end

  describe "#append_learnings" do
    it "appends new learnings with timestamp" do
      File.write(learnings_path, "")
      updater = Rralph::FileUpdater.new(todo_path: todo_path, learnings_path: learnings_path)

      updater.append_learnings(["Ruby is great", "Thor makes CLIs easy"])

      content = File.read(learnings_path)
      expect(content).to match(/## Learnings - \d{4}-\d{2}-\d{2}/)
      expect(content).to include("- Ruby is great")
      expect(content).to include("- Thor makes CLIs easy")
    end

    it "deduplicates existing learnings" do
      File.write(learnings_path, "- Ruby is great\n")
      updater = Rralph::FileUpdater.new(todo_path: todo_path, learnings_path: learnings_path)

      updater.append_learnings(["Ruby is great", "New learning"])

      content = File.read(learnings_path)
      expect(content.scan("Ruby is great").size).to eq(1)
      expect(content).to include("New learning")
    end

    it "does nothing when learnings array is empty" do
      File.write(learnings_path, "Existing content")
      updater = Rralph::FileUpdater.new(todo_path: todo_path, learnings_path: learnings_path)

      updater.append_learnings([])

      content = File.read(learnings_path)
      expect(content).to eq("Existing content")
    end
  end

  describe "#todo_empty?" do
    it "returns true when no pending tasks" do
      File.write(todo_path, "- [x] Task 1\n- [x] Task 2")
      updater = Rralph::FileUpdater.new(todo_path: todo_path, learnings_path: learnings_path)

      expect(updater.todo_empty?).to be true
    end

    it "returns false when pending tasks exist" do
      File.write(todo_path, "- [ ] Task 1\n- [x] Task 2")
      updater = Rralph::FileUpdater.new(todo_path: todo_path, learnings_path: learnings_path)

      expect(updater.todo_empty?).to be false
    end

    it "returns true when file doesn't exist" do
      updater = Rralph::FileUpdater.new(todo_path: "/nonexistent.md", learnings_path: learnings_path)
      expect(updater.todo_empty?).to be true
    end
  end
end
