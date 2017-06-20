Devise.setup do |config|

    config.secret_key = 'ac5e2a50ff2ae1cffb91397787c6bc2eec791518389f1329f0e0a271c412d850afdf092e3eba0b1c3125de435433aa833f4f3a839c5408579a9caf3ecdaa6374'
    config.mailer_sender = 'info@workspace.com'
    require 'devise/orm/mongoid'
    config.case_insensitive_keys = [:email, :username]
    config.strip_whitespace_keys = [:email, :username]
    config.skip_session_storage = [:http_auth]
    config.stretches = Rails.env.test? ? 1 : 10
    config.pepper = '193e171c269392ee0b3047cbfef718231f96e3229969867d836137e5063ea7792227adcc1cd9aed501a204dbb7317200df1f17771782440facc8fdb6e60acf73'
    config.send_password_change_notification = false
    config.reconfirmable = true
    config.expire_all_remember_me_on_sign_out = true
    config.password_length = 8..72
    config.reset_password_within = 6.hours
    config.sign_in_after_reset_password = true
    config.sign_out_via = :delete
    config.authentication_keys = [ :email ]
    config.scoped_views = true
end
