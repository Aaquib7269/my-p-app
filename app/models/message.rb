class Message
    include Common

    field :message_text, type: String
    belongs_to :product, :class_name => "Product", :index => true, :inverse_of => :product
    belongs_to :user_one, :class_name => "User", :index => true, :inverse_of => :user_one
    belongs_to :user_two, :class_name => "User", :index => true, :inverse_of => :user_two

    after_save do

        owner_id = self.product.user.id.to_s
        buyer_id = self.product.sold_to.id.to_s
        
        owner = User.find(owner_id)
        buyer = User.find(buyer_id)

        if self.user_one.id.to_s == owner.id.to_s
            RedisServer.instance.push_message(self.product, owner, { :message => self.message_text, :id => self.id.to_s })
        else
            RedisServer.instance.push_message(self.product, buyer, { :message => self.message_text, :id => self.id.to_s })
        end

        message_sent_by = self.user_one

        if message_sent_by.id.to_s != owner_id
            if RedisServer.instance.subscribed?(self.product, owner) == false
                notification_string = owner.language_selected == 0 ? "#{message_sent_by.full_name} has sent you a message" : "#{message_sent_by.full_name} has sent you a message"
                data_one = {:action => "open_chat", :item_id => self.product.id.to_s, :item_name => self.product.product_name}
                PushJob.new.send_notification(owner, notification_string, data_one)
                PushJob.new.send_android_notification(owner, notification_string, data_one)
                Rails.logger.info("Sending note one")
            end
        else
            if RedisServer.instance.subscribed?(self.product, buyer) == false
                notification_string = buyer.language_selected == 0 ? "#{message_sent_by.full_name} has sent you a message" : "#{message_sent_by.full_name} has sent you a message"
                data_one = {:action => "open_chat", :item_id => self.product.id.to_s, :item_name => self.product.product_name}
                PushJob.new.send_notification(buyer, notification_string, data_one)
                PushJob.new.send_android_notification(buyer, notification_string, data_one)
                Rails.logger.info("Sending note two")
            end
        end
        
    end

    def to_api
    	return {

    				:id => self.id.to_s,
    				:message => self.message_text,
    				:thumb_url => self.user_one.blank? ? "" : self.user_one.avatar.blank? ? "" : "#{self.user_one.avatar.url}",
    				:username => self.user_one.blank? ? "" : self.user_one.email_address
    	}
    end
end
