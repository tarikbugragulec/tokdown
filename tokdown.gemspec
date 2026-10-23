# frozen_string_literal: true

require_relative "lib/tokdown/version"

Gem::Specification.new do |spec|
  spec.name          = "tokdown"
  spec.version       = TokDown::VERSION
  spec.authors       = ["TokDown Contributors"]
  spec.email         = ["dev@tokdown.dev"]

  spec.summary       = "High-performance LLM token reduction engine and CLI for JSON, YAML, and structured data"
  spec.description   = "TokDown cuts LLM prompt token costs by up to 70% using intelligent schema tabularization, Token-Optimized Object Notation (TOON), and pure-Ruby BPE token estimation."
  spec.homepage      = "https://github.com/tarikbugragulec/tokdown"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "bin/*", "LICENSE", "README.md"]
  spec.bindir = "bin"
  spec.executables = ["tokdown"]
  spec.require_paths = ["lib"]

  # Optional runtime enhancements
  # spec.add_development_dependency "rspec", "~> 3.12"
  # spec.add_development_dependency "rubocop", "~> 1.60"
end
