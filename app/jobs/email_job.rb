class EmailJob
    include SuckerPunch::Job

    def send_email_to(full_name, email_address, subject, email_text)
    	user = User.find_by(:email_address => email_address)
    	if user.email_notification == true
        	NotificationMailer.email_notification(full_name, email_address, subject, email_text).deliver
        end
    end

    def send_welcome_email_to(email_address)
    	@user = User.find_by(:email_address => email_address)
    	key = "49f9ceb472a7c3d24bb3fd38f6e1647d13c01d2e8ed03a72230c4641dabff0789f89a4cae83823378277138579d945a4733c24903e90201f8c1059947338e2b5"
        crypt = ActiveSupport::MessageEncryptor.new(key)
    	@password = crypt.decrypt_and_verify(@user.encrypted_password)
    	NotificationMailer.welcome_email_notification(email_address, "Velkommen til SHAPP", @password).deliver
    end
end
