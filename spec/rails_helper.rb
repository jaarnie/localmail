require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

Dir[File.join(__dir__, "support/**/*.rb")].each { |file| require file }

ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(Localmail::Engine.root.join("db/migrate").to_s).migrate

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.use_transactional_fixtures = true
  config.include ActiveSupport::Testing::TimeHelpers

  RedisAvailability.configure(config)

  config.before do
    Localmail.reset_config!
    Localmail::Store.clear
  end

  config.before(:each, :redis) do
    Localmail.configure { |localmail| localmail.store = :redis }
    Localmail::Store.clear
  end

  config.after(:each, :redis) { Localmail::Store.clear }
end
