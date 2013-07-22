require 'rack/file'
require 'capybara/rspec'
require 'capybara/poltergeist'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
  
  config.include Capybara::DSL
end

Capybara.default_driver = :poltergeist 
Capybara.app = Rack::File.new File.expand_path(File.join(File.dirname(__FILE__), '..', 'public'))