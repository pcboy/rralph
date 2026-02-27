require "spec_helper"
require "rralph"

RSpec.describe Rralph::CLI do
  describe "command line options" do
    before do
      allow(Rralph::Runner).to receive(:new).and_return(double("Runner", run: true))
    end

    it "accepts --max-failures option" do
      expect { Rralph::CLI.start(["--max-failures", "5"]) }
        .to_not raise_error
    end

    it "accepts --ai-command option" do
      expect { Rralph::CLI.start(["--ai-command", "custom-ai"]) }
        .to_not raise_error
    end

    it "accepts --watch option" do
      expect { Rralph::CLI.start(["--watch"]) }
        .to_not raise_error
    end

    it "accepts --plan-path option" do
      expect { Rralph::CLI.start(["--plan-path", "custom_plan.md"]) }
        .to_not raise_error
    end

    it "accepts --learnings-path option" do
      expect { Rralph::CLI.start(["--learnings-path", "custom_learnings.md"]) }
        .to_not raise_error
    end

    it "accepts --todo-path option" do
      expect { Rralph::CLI.start(["--todo-path", "custom_todo.md"]) }
        .to_not raise_error
    end

    it "accepts --skip-commit option" do
      expect { Rralph::CLI.start(["--skip-commit"]) }
        .to_not raise_error
    end

    it "accepts -s as alias for --skip-commit" do
      expect { Rralph::CLI.start(["-s"]) }
        .to_not raise_error
    end

    it "shows version with version command" do
      expect { Rralph::CLI.start(["version"]) }
        .to output(/rralph v#{Rralph::VERSION}/).to_stdout
    end
  end

  describe "skip-commit option is passed to Runner" do
    let(:runner_double) { double("Runner", run: true) }

    before do
      allow(Rralph::Runner).to receive(:new).and_return(runner_double)
    end

    it "passes skip_commit: true when --skip-commit is provided" do
      expect(Rralph::Runner).to receive(:new).with(hash_including(skip_commit: true))
      Rralph::CLI.start(["--skip-commit"])
    end

    it "passes skip_commit: true when -s is provided" do
      expect(Rralph::Runner).to receive(:new).with(hash_including(skip_commit: true))
      Rralph::CLI.start(["-s"])
    end

    it "passes skip_commit: false by default" do
      expect(Rralph::Runner).to receive(:new).with(hash_including(skip_commit: false))
      Rralph::CLI.start([])
    end
  end
end
