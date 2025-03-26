# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'appimage-to-app'
  spec.version       = '0.1.0'
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']

  spec.summary       = 'Convert AppImages into native-like desktop applications'
  spec.description   = 'Easily convert AppImages into searchable and launchable desktop applications'
  spec.homepage      = 'https://github.com/yourusername/appimage-to-app'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob('{bin,lib}/**/*')
  spec.bindir        = 'bin'
  spec.executables   = ['ata']
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'colorize', '~> 1.1'
  spec.add_dependency 'fileutils', '~> 1.7'
  spec.add_dependency 'pathname', '~> 0.2'

  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.23'
end 