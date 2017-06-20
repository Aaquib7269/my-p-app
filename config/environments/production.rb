Rails.application.configure do

    config.cache_classes = true
    config.eager_load = true

    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = true

    config.serve_static_files = true
    config.assets.js_compressor = :uglifier
    config.assets.css_compressor = :sass
    config.assets.compile = true
    config.assets.digest = true
    config.assets.version = '1.0'
    config.assets.logger = false
    config.assets.debug = false
    config.static_cache_control = "public, max-age=3600"

    config.log_level = :debug
    config.log_tags = [ :subdomain ]
    config.i18n.fallbacks = true
    config.active_support.deprecation = :notify
    config.log_formatter = ::Logger::Formatter.new

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
        :enable_starttls_auto => true
    }

    config.preload_frameworks = true
    config.allow_concurrency = true

end
