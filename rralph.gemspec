Gem::Specification.new do |spec|
  spec.name = "rralph"
  spec.version = "0.1.0"
  spec.authors = ["rralph"]
  spec.email = ["david@joynetiks.com"]

  spec.summary = "A self-improving task orchestrator for AI-assisted development"
  spec.description = "rralph automates an iterative, AI-assisted development workflow by reading plan.md, learnings.md, and todo.md, then orchestrating AI tool invocations to complete tasks."
  spec.homepage = "https://github.com/pcboy/rralph"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "bin/rralph", "README.md", "LICENSE"]
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.5"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "solargraph", "~> 0.58"
end
