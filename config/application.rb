require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Shapp
    class Application < Rails::Application
        config.generators.stylesheets = false
        config.generators.javascripts = false
        config.generators.test_framework false
        config.middleware.delete Rack::Lock
        config.active_job.queue_adapter = :delayed_job
        
        config.active_support.escape_html_entities_in_json = true
        config.autoload_paths += %W(#{config.root}/lib)
        config.assets.enabled = true
        config.assets.version = '1.0'
        
        config.assets.paths << "#{Rails.root}/app/assets/images/landing"
        config.assets.paths << "#{Rails.root}/app/assets/images/app"
        
        config.assets.paths << "#{Rails.root}/app/assets/fonts/app"
        config.assets.paths << "#{Rails.root}/app/assets/fonts/landing"

        config.generators.helper = false

        config.to_prepare do
            Devise::SessionsController.layout "app"
            Devise::RegistrationsController.layout proc{ |controller| admin_signed_in? ? "app"   : "app" }
            Devise::ConfirmationsController.layout "app"
            Devise::UnlocksController.layout "app"            
            Devise::PasswordsController.layout "app"        
        end
    end
end
