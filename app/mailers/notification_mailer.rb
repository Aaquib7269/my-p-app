class NotificationMailer < ApplicationMailer
    default from: "info@shapp.dk"
    
    def email_notification(user_name, user_email, subject, email_text)
    	@user_name = user_name
        @email_text = email_text
    	mail(to: user_email, subject: subject)
        puts "Sending email"
	end

	def welcome_email_notification(user_email, subject, password)
		key = "49f9ceb472a7c3d24bb3fd38f6e1647d13c01d2e8ed03a72230c4641dabff0789f89a4cae83823378277138579d945a4733c24903e90201f8c1059947338e2b5"
        crypt = ActiveSupport::MessageEncryptor.new(key)
        @encrypted_email = crypt.encrypt_and_sign(user_email)
    	@user_email = user_email
    	@password = password
    	mail(to: user_email, subject: subject)
        puts "Sending email"
	end
end
