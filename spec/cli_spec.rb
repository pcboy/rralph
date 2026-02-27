require "spec_helper"
require "rralph"

RSpec.describe Rralph::CLI do
  describe "command line options" do
    it "accepts --max-failures option" do
      expect { Rralph::CLI.start(["--max-failures", "5"]) }
        .to output(/Starting rralph/).to_stderr
    end

    it "accepts --ai-command option" do
      expect { Rralph::CLI.start(["--ai-command", "custom-ai"]) }
        .to output(/ai_command='custom-ai'/).to_stderr
    end

    it "accepts --watch option" do
      expect { Rralph::CLI.start(["--watch"]) }
        .to output(/Starting rralph/).to_stderr
    end

    it "accepts --plan-path option" do
      expect { Rralph::CLI.start(["--plan-path", "custom_plan.md"]) }
        .to output(/Starting rralph/).to_stderr
    end

    it "accepts --learnings-path option" do
      expect { Rralph::CLI.start(["--learnings-path", "custom_learnings.md"]) }
        .to output(/Starting rralph/).to_stderr
    end

    it "accepts --todo-path option" do
      expect { Rralph::CLI.start(["--todo-path", "custom_todo.md"]) }
        .to output(/Starting rralph/).to_stderr
    end

    it "accepts --skip-commit option" do
      expect { Rralph::CLI.start(["--skip-commit"]) }
        .to output(/Starting rralph/).to_stderr
    end

    it "accepts -s as alias for --skip-commit" do
      expect { Rralph::CLI.start(["-s"]) }
        .to output(/Starting rralph/).to_stderr
    end

    it "shows version with version command" do
      expect { Rralph::CLI.start(["version"]) }
        .to output(/rralph v#{Rralph::VERSION}/).to_stdout
    end
  end
end
