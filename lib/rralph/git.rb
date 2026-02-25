require "shellwords"

module Rralph
  class Git
    def initialize
    end

    def in_git_repo?
      result = `git rev-parse --git-dir 2>/dev/null`
      $?.success?
    end

    def commit_changes(message)
      add_result = `git add . 2>&1`
      unless $?.success?
        raise GitError, "Failed to stage files: #{add_result}"
      end

      commit_result = `git commit -m #{message.shellescape} 2>&1`
      unless $?.success?
        raise GitError, "Failed to commit: #{commit_result}"
      end

      sha = `git rev-parse --short HEAD 2>/dev/null`.strip
      sha
    end

    def status
      `git status --short 2>/dev/null`
    end

    def has_changes?
      status = `git status --porcelain 2>/dev/null`
      !status.empty?
    end
  end
end
