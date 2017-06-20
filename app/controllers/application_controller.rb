class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :configure_permitted_parameters, if: :devise_controller?

    def configure_permitted_parameters
        devise_parameter_sanitizer.for(:account_update) { |u|
            u.permit(:password, :password_confirmation, :current_password, :email, :first_name, :last_name) 
        }
    end

    def after_sign_in_path_for(resource)
        admin_path
    end
end
