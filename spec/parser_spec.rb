require "spec_helper"
require "rralph"

RSpec.describe Rralph::Parser do
  let(:parser) { Rralph::Parser.new }

  describe "#failure_detected?" do
    it "returns true when response contains FAILURE" do
      expect(parser.failure_detected?("This is a FAILURE")).to be true
    end

    it "returns true for case-insensitive FAILURE" do
      expect(parser.failure_detected?("This is a failure")).to be true
      expect(parser.failure_detected?("This is a Failure")).to be true
      expect(parser.failure_detected?("FAILURE occurred")).to be true
    end

    it "returns true when FAILURE is a whole word" do
      expect(parser.failure_detected?("Test FAILURE detected")).to be true
    end

    it "returns false when failure is part of another word" do
      expect(parser.failure_detected?("This is unfailed")).to be false
    end

    it "returns false when no failure keyword" do
      expect(parser.failure_detected?("Everything went well")).to be false
    end
  end

  describe "#pending_tasks" do
    let(:todo_content) do
      <<~TODO
        # Todo List

        - [ ] Implement feature A
        - [x] Complete feature B
        - [ ] Write tests for C
        * [ ] Another task with asterisk
      TODO
    end

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with("plan.md").and_return("# Plan")
      allow(File).to receive(:read).with("learnings.md").and_return("")
      allow(File).to receive(:read).with("todo.md").and_return(todo_content)
      parser.load_files
    end

    it "returns only pending tasks" do
      pending_tasks = parser.pending_tasks
      expect(pending_tasks.size).to eq(3)
    end

    it "extracts task text correctly" do
      pending_tasks = parser.pending_tasks
      expect(pending_tasks.first[:text]).to eq("Implement feature A")
    end

    it "handles both dash and asterisk formats" do
      pending_tasks = parser.pending_tasks
      expect(pending_tasks.last[:text]).to eq("Another task with asterisk")
    end

    it "includes line index" do
      pending_tasks = parser.pending_tasks
      expect(pending_tasks.first[:index]).to be_a(Integer)
    end
  end

  describe "#completed_tasks" do
    let(:todo_content) do
      <<~TODO
        # Todo List

        - [ ] Implement feature A
        - [x] Complete feature B
        - [ ] Write tests for C
      TODO
    end

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with("plan.md").and_return("# Plan")
      allow(File).to receive(:read).with("learnings.md").and_return("")
      allow(File).to receive(:read).with("todo.md").and_return(todo_content)
      parser.load_files
    end

    it "returns only completed tasks" do
      completed_tasks = parser.completed_tasks
      expect(completed_tasks.size).to eq(1)
      expect(completed_tasks.first[:text]).to eq("Complete feature B")
    end
  end

  describe "#has_pending_tasks?" do
    it "returns true when there are pending tasks" do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with("plan.md").and_return("# Plan")
      allow(File).to receive(:read).with("learnings.md").and_return("")
      allow(File).to receive(:read).with("todo.md").and_return("- [ ] Task 1")
      parser.load_files

      expect(parser.has_pending_tasks?).to be true
    end

    it "returns false when all tasks are completed" do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with("plan.md").and_return("# Plan")
      allow(File).to receive(:read).with("learnings.md").and_return("")
      allow(File).to receive(:read).with("todo.md").and_return("- [x] Task 1")
      parser.load_files

      expect(parser.has_pending_tasks?).to be false
    end
  end

  describe "#extract_learnings" do
    it "extracts learnings from labeled sections" do
      response = <<~RESPONSE
        Here's what I found:
        
        Learning: Ruby uses snake_case for methods
        Insight: Thor is great for CLIs
      RESPONSE

      learnings = parser.extract_learnings(response)
      expect(learnings).to include("Ruby uses snake_case for methods")
      expect(learnings).to include("Thor is great for CLIs")
    end

    it "extracts learnings from markdown sections" do
      response = <<~RESPONSE
        Task completed.
        
        ## Learnings
        
        - Ruby 3.4 has new features
        - Thor handles CLI parsing
      RESPONSE

      learnings = parser.extract_learnings(response)
      expect(learnings).to include("Ruby 3.4 has new features")
      expect(learnings).to include("Thor handles CLI parsing")
    end

    it "returns empty array when no learnings found" do
      response = "Task completed successfully"
      learnings = parser.extract_learnings(response)
      expect(learnings).to be_empty
    end
  end

  describe "#build_prompt" do
    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with("plan.md").and_return("# My Plan")
      allow(File).to receive(:read).with("learnings.md").and_return("- Learning 1")
      allow(File).to receive(:read).with("todo.md").and_return("- [ ] Task 1")
      parser.load_files
    end

    it "includes all file contents in prompt" do
      prompt = parser.build_prompt
      expect(prompt).to include("# My Plan")
      expect(prompt).to include("- Learning 1")
      expect(prompt).to include("- [ ] Task 1")
    end

    it "includes the standard instruction header" do
      prompt = parser.build_prompt
      expect(prompt).to include("Original plan: @plan.md")
      expect(prompt).to include("Learnings: @learnings.md")
      expect(prompt).to include("Todo list: @todo.md")
    end
  end
end
