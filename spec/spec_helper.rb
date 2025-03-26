# frozen_string_literal: true

require 'bundler/setup'
require 'rspec'
require 'fileutils'
require 'pathname'

# Add the lib directory to the load path
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use the documentation formatter for detailed output
  config.default_formatter = 'doc' if config.files_to_run.one?

  # Run specs in random order to surface order dependencies
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option
  Kernel.srand config.seed
end 