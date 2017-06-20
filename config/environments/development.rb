Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.active_support.deprecation = :log
  config.assets.debug = true
  config.assets.digest = true
  config.assets.raise_runtime_errors = true
  config.action_mailer.default_url_options = { :host => "shapp.dk" }
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.default :charset => "utf-8"
    config.action_mailer.smtp_settings = {
        :address              => "smtp.zoho.com",
        :port                 => 587,
        :domain               => 'zoho.com',
        :user_name            => "info@shapp.dk",
        :password             => "shapp@123",
        :authentication       => :plain,
        }
end