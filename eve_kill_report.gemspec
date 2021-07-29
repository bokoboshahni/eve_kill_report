# frozen_string_literal: true

require_relative "lib/eve_kill_report/version"

Gem::Specification.new do |spec|
  spec.name          = "eve_kill_report"
  spec.version       = EVEKillReport::VERSION
  spec.authors       = ["BokoboShahni"]
  spec.email         = ["shahni@bokobo.space"]

  spec.summary       = "Generate killmail reports for EVE Online"
  spec.description   = "EVE Kill Report generates detailed killmail reports for EVE Online from publicly-available killmail data on zKillboard and ESI."
  spec.homepage      = "https://github.com/bokoboshahni/eve_kill_report"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bokoboshahni/eve_kill_report"
  spec.metadata["changelog_uri"] = "https://github.com/bokoboshahni/eve_kill_report/tree/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport'
  spec.add_dependency 'caxlsx'
  spec.add_dependency 'concurrent-ruby'
  spec.add_dependency 'concurrent-ruby-edge'
  spec.add_dependency 'concurrent-ruby-ext'
  spec.add_dependency 'down'
  spec.add_dependency 'google-apis-drive_v3'
  spec.add_dependency 'google-apis-sheets_v4'
  spec.add_dependency 'httpx'
  spec.add_dependency 'kiba'
  spec.add_dependency 'retriable'
  spec.add_dependency 'thor'
  spec.add_dependency 'tty-color'
  spec.add_dependency 'tty-link'
  spec.add_dependency 'tty-logger'
  spec.add_dependency 'tty-progressbar'
  spec.add_dependency 'tty-table'
end
