module Rralph
  VERSION = "0.1.2"

  class Error < StandardError; end
  class FileNotFound < Error; end
  class GitError < Error; end
  class AICommandError < Error; end
end

require_relative "rralph/parser"
require_relative "rralph/file_updater"
require_relative "rralph/git"
require_relative "rralph/runner"
require_relative "rralph/cli"
