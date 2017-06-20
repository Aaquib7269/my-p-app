class Bid
  	include Common

  	field :bid_amount, type: Float
    field :accepted, type: Mongoid::Boolean, :default => false
    field :accepted_rejected_on, type: Time

  	belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
  	belongs_to :product, :class_name => "Product", :index => true, :inverse_of => :product

    after_create do
        if self.bid_amount > 0
            product_images = self.product.product_images.reject{|i| i.image_upload.blank? }
            product_image_path = ""
            if product_images.count > 0
                product_image_path = "#{product_images.first.image_upload.url}"
            end
            user = self.product.user
            notification_string = user.language_selected == 0 ? "There have been bid placed on your product #{self.product.product_name}" : "Der er kommet et bud på dit produkt #{self.product.product_name}"
            data_one = {:action => "open_bid_list", :item_id => self.product.id.to_s}
            PushJob.new.send_notification(user, notification_string, data_one)
            PushJob.new.send_android_notification(user, notification_string, data_one)
            user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_bid_list", :item_id => self.product.id.to_s, :item_image => product_image_path)
            EmailJob.new.send_email_to(user.full_name, user.email_address, notification_string, notification_string)

            existing_users = Bid.where(:product_id => self.product.id).reject{|b| b.user_id = user.id}
            data_two = {:action => "open_my_bids", :item_id => self.product.id.to_s}
            existing_users.each do |existing_user|
                notification_string = existing_user.language_selected == 0 ? "There have been bid on the items you have bid on" : "Der er blevet budt på det produkt du har budt på "
                PushJob.new.send_notification(existing_user, notification_string, data_two)
                PushJob.new.send_android_notification(existing_user, notification_string, data_two)
                existing_user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_my_bids", :item_id => self.product.id.to_s, :item_image => product_image_path)
                EmailJob.new.send_email_to(existing_user.full_name, existing_user.email_address, notification_string, notification_string)
            end

            users_saved = SavedShapp.where(:product_id => self.product.id).map(&:user)
            data_three = {:action => "open_my_bids", :item_id => self.product.id.to_s}
            users_saved.each do |saved_user|
                notification_string = saved_user.language_selected == 0 ? "There have been bid on the items you follow" : "Der er blevet budt på det produkt du følger"
                PushJob.new.send_notification(saved_user, notification_string, data_three)
                PushJob.new.send_android_notification(saved_user, notification_string, data_three)
                saved_user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_my_bids", :item_id => self.product.id.to_s, :item_image => product_image_path)
                EmailJob.new.send_email_to(saved_user.full_name, saved_user.email_address, notification_string, notification_string)
            end            
        end
    end

    def to_api
        return {
                    :id => self.id.to_s,
                    :uploaded_by_name => self.user.full_name,
                    :uploaded_by_id => self.user.id.to_s,
                    :uploaded_in => self.user.my_location,
                    :uploaded_by_image => self.user.avatar.blank? ? "" : "#{self.user.avatar.url}",
                    :bid_amount => self.bid_amount,
                    :bid_accepted => self.accepted == true ? 1 : 0
                }
    end
end
