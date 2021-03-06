# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require 'simplecov'
SimpleCov.start do
  add_filter '/config/'
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Libraries', 'lib'
  add_group 'Specs', 'spec'
end

require File.expand_path('../dummy_app/config/environment', __FILE__)

require 'rails/test_help'
require 'generator_spec/test_case'
require 'generators/rails_admin/install_migrations_generator'
require File.dirname(__FILE__) + '/../lib/rails_admin/tasks/install'
require File.dirname(__FILE__) + '/../lib/rails_admin/tasks/uninstall'
require 'generators/rails_admin/uninstall_migrations_generator'
require 'generators/rails_admin/rails_admin_generator'
require 'rspec/rails'
require 'factory_girl'
require 'factories'
require 'database_helpers'
require 'generator_helpers'

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "example.com"

Rails.backtrace_cleaner.remove_silencers!

include DatabaseHelpers
# Run any available migration
puts 'Setting up database...'
drop_all_tables
migrate_database

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each{|f| require f}

# Don't need passwords in test DB to be secure, but we would like 'em to be
# fast -- and the stretches mechanism is intended to make passwords
# computationally expensive.
module Devise
  module Models
    module DatabaseAuthenticatable
      protected

      def password_digest(password)
        password
      end
    end
  end
end
Devise.setup do |config|
  config.stretches = 0
end

RSpec.configure do |config|
  require 'rspec/expectations'

  config.include RSpec::Matchers
  config.include DatabaseHelpers
  config.include GeneratorHelpers
  config.include RailsAdmin::Engine.routes.url_helpers

  config.include Warden::Test::Helpers

  config.before(:each) do
    RailsAdmin.setup
    RailsAdmin::Config.excluded_models = [RelTest, FieldTest]
    RailsAdmin::AbstractModel.all_models = nil
    RailsAdmin::AbstractModel.all_abstract_models = nil
    RailsAdmin::AbstractModel.new("Division").destroy_all!
    RailsAdmin::AbstractModel.new("Draft").destroy_all!
    RailsAdmin::AbstractModel.new("Fan").destroy_all!
    RailsAdmin::AbstractModel.new("League").destroy_all!
    RailsAdmin::AbstractModel.new("Player").destroy_all!
    RailsAdmin::AbstractModel.new("Team").destroy_all!
    RailsAdmin::AbstractModel.new("User").destroy_all!
    RailsAdmin::History.destroy_all

    user = RailsAdmin::AbstractModel.new("User").create(
      :email => "username@example.com",
      :password => "password"
    )

    login_as user
  end

  config.after(:each) do
    RailsAdmin.test_reset!
    Warden.test_reset!
  end
end
