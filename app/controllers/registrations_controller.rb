class RegistrationsController < Devise::RegistrationsController
    def update
        account_update_params = devise_parameter_sanitizer.sanitize(:account_update)
        @admin = Admin.find(current_admin.id)
        if needs_password?
            successfully_updated = @admin.update_with_password(account_update_params)
        else
            account_update_params.delete('password')
            account_update_params.delete('password_confirmation')
            account_update_params.delete('current_password')
            successfully_updated = @admin.update_attributes(account_update_params)
        end

        if successfully_updated
            set_flash_message :notice, :updated
            sign_in @admin, :bypass => true
            redirect_to edit_admin_registration_path
        else
            render 'edit'
        end
    end

    private
    def needs_password?
        @admin.email != params[:admin][:email] || params[:admin][:password].present?
    end
end
