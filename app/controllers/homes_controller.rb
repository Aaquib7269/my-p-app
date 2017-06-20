class HomesController < ApplicationController
    layout 'landing'
    skip_before_action :verify_authenticity_token
    def index
    end

    def contact
    	if params[:full_name].blank? || params[:email_address].blank? || params[:message].blank?
    		flash[:error] = "All fields are required"
    		redirect_to "/#contact"
    	else
    		@contact = Contact.find_or_create_by(:full_name => params[:full_name], :email_address => params[:email_address], :message => params[:message])
    		if @contact
    			flash[:error] = "Thank you. Our executive will contact you shortly"
    		end
    		redirect_to "/#contact"
    	end
    end

    def confirm_account
        key = "49f9ceb472a7c3d24bb3fd38f6e1647d13c01d2e8ed03a72230c4641dabff0789f89a4cae83823378277138579d945a4733c24903e90201f8c1059947338e2b5"
        crypt = ActiveSupport::MessageEncryptor.new(key)
        @decrypted_email = crypt.decrypt_and_verify(params[:u])
        @user = User.find_by(:email_address => @decrypted_email)
        @status = 0
        if @user.blank?
            @status = 0
        else
            @user.update_attributes(:is_active => true)
            @status = 1
        end
    end
end
