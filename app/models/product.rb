class Product
    include Common

    field :product_name, type: String
    field :product_description, type: String
    field :bid_start, type: Time
    field :bid_end, type: Time
    field :bill_included, type: Mongoid::Boolean
    field :is_approved, type: Mongoid::Boolean, :default => false
    field :min_bid_price, type: Float
    field :buy_now_price, type: Float
    field :latitude, type: Float
    field :longitude, type: Float
    field :sold_email_sent, type: Mongoid::Boolean, :default => false
    field :show_in_both, type: Mongoid::Boolean, :default => false
    
    mount_uploader :product_video, VideoUploader

    has_many :bids, :dependent => :destroy
    has_many :comments, :dependent => :destroy
    has_many :product_views, :dependent => :destroy
    has_many :product_images, :dependent => :destroy
    has_many :product_ratings, :dependent => :destroy
    has_many :product_reports, :dependent => :destroy

    belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
    belongs_to :category, :class_name => "Category", :index => true, :inverse_of => :category
    belongs_to :brand, :class_name => "Brand", :index => true, :inverse_of => :brand
    belongs_to :quality, :class_name => "Quality", :index => true, :inverse_of => :quality
    belongs_to :item_model, :class_name => "ItemModel", :index => true, :inverse_of => :item_model
    belongs_to :sold_to, :class_name => "User", :index => true, :inverse_of => :sold_to
    belongs_to :group, :class_name => "Group", :index => true, :inverse_of => :group

    validates_presence_of :product_name, :message => "Product name is required"
    validates_presence_of :product_description, :message => "Product description is required"
    validates_presence_of :min_bid_price, :message => "Minimum bid price is required"
    validates_presence_of :buy_now_price, :message => "Buy now price is required"
    validates_numericality_of :buy_now_price, :greater_than => :min_bid_price, :message => "Buy now price should be greater than min bid price"
    after_create do
        product_images = self.product_images.reject{|i| i.image_upload.blank? }
        product_image_path = ""
        if product_images.count > 0
            product_image_path = "#{product_images.first.image_upload.url}"
        end
        if !self.group.blank?
            if self.group.followers.count > 0
                user_ids = self.group.followers.map(&:f_id)
                users = User.where(:id.in => user_ids)
                users.all.each do |user|
                    notification_string = user.language_selected == 0 ? "There have been placed items for sale in your group" : " Der er nye produkter til salg i din gruppe"
                    data_one = {:action => "open_product", :item_id => self.id.to_s}
                    PushJob.new.send_notification(user, notification_string, data_one)
                    PushJob.new.send_android_notification(user, notification_string, data_one)
                    user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_product", :item_id => self.id.to_s, :item_image => product_image_path)
                    EmailJob.new.send_email_to(user.full_name, user.email_address, "Bid placed for items for sale in your group", notification_string)
                end
            end
        end

        if !self.bid_end.blank?
            Delayed::Job.enqueue(Product.send_time_remaining_notification(self.id), 3, self.bid_end - 10.minutes)
            Delayed::Job.enqueue(Product.send_auction_closed_notification(self.id), 3, self.bid_end)
        end

    end

    after_update do
        if !self.sold_to.blank?
            product_images = self.product_images.reject{|i| i.image_upload.blank? }
            product_image_path = ""
            if product_images.count > 0
                product_image_path = "#{product_images.first.image_upload.url}"
            end
            notification_string = self.user.language_selected == 0 ? "#{self.sold_to.full_name} has buyed your product #{self.product_name}" : "#{self.sold_to.full_name} har købt dit produkt"
            data_one = {:action => "open_product", :item_id => self.id.to_s}
            PushJob.new.send_notification(self.user, notification_string, data_one)
            PushJob.new.send_android_notification(self.user, notification_string, data_one)
            self.user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_product", :item_id => self.id.to_s, :item_image => product_image_path)
            EmailJob.new.send_email_to(self.user.full_name, self.user.email_address, notification_string, notification_string)
        end
    end

    before_destroy do
        SavedShapp.where(:product_id => self.id).destroy_all
        RejectedProduct.where(:product_id => self.id).destroy_all
        Bid.where(:product_id => self.id).destroy_all
        Notification.where(:item_id => self.id).destroy_all
    end

    def self.send_time_remaining_notification(product_id)
        product = Product.find(product_id)
        product_images = product.product_images.reject{|i| i.image_upload.blank? }
        product_image_path = ""
        if product_images.count > 0
            product_image_path = "#{product_images.first.image_upload.url}"
        end
        bidded_users = product.bids.map(&:user_id)
        users = User.where(:id.in => bidded_users)
        users.each do |user|
            notification_string = user.language_selected == 0 ? "The auction ends on 10 min for #{product.product_name}" : "Auktionen slutter om 10 min #{product.product_name}"
            data_one = {:action => "open_product", :item_id => self.id.to_s}
            PushJob.new.send_notification(user, notification_string, data_one)
            PushJob.new.send_android_notification(user, notification_string, data_one)
            user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_product", :item_id => self.id.to_s, :item_image => product_image_path)
            EmailJob.new.send_email_to(user.full_name, user.email_address, notification_string, notification_string)
        end
    end

    def self.send_auction_closed_notification(product_id)
        product = Product.find(product_id)
        product_images = product.product_images.reject{|i| i.image_upload.blank? }
        product_image_path = ""
        if product_images.count > 0
            product_image_path = "#{product_images.first.image_upload.url}"
        end
        bidded_users = product.bids.map(&:user_id)
        users = User.where(:id.in => bidded_users)
        users.each do |user|
            notification_string = user.language_selected == 0 ? "The auction is closed for #{product.product_name}" : "Auktionen er lukket for #{product.product_name}"
            data_one = {:action => "open_product", :item_id => self.id.to_s}
            PushJob.new.send_notification(user, notification_string, data_one)
            PushJob.new.send_android_notification(user, notification_string, data_one)
            user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_product", :item_id => self.id.to_s, :item_image => product_image_path)
            EmailJob.new.send_email_to(user.full_name, user.email_address, notification_string, notification_string)
        end
        last_bid = product.bids.where(:bid_amount => product.bids.max(:bid_amount)).last
        last_bid.update_attributes(:accepted => true)
        product.update_attributes(:sold_to => last_bid.user)
        data_one = {:action => "open_product", :item_id => self.id.to_s}
        sold_notification_string = last_bid.user.language_selected == 0 ? "Congratulations! You've won the auction! for #{product.product_name}" : "Tillykke! Du har vundet auktionen! for #{product.product_name}"
        PushJob.new.send_notification(last_bid.user, notification_string, data_one)
        PushJob.new.send_android_notification(last_bid.user, notification_string, data_one)
        last_bid.user.notifications.create(:notification_string => notification_string, :notification_type => 1, :action => "open_product", :item_id => self.id.to_s, :item_image => product_image_path)
        EmailJob.new.send_email_to(last_bid.user.full_name, last_bid.user.email_address, notification_string, notification_string)
    end

    def bid_closed?
        if self.sold_to_id.blank?
            if self.bid_start.blank? || self.bid_end.blank?
                return true
            else
                if self.bid_start < Time.zone.now && self.bid_end > Time.zone.now
                    return false
                else
                    return true
                end
            end
        else
            return true
        end
    end

    def self.search(search)
        if search
            any_of({:name => /#{search}/i}, {:description => /#{search}/i}, {:min_bid_price => /#{search}/i}, {:buy_now_price => /#{search}/i})
        end
    end

    def to_discover(user, device_width)
        user_max_bid_on_product = 0.0
        if user.blank?
            user_max_bid_on_product = 0.0
        else
            user_max_bid_on_product = user.bids.where(:product_id => self.id).count > 0 ? user.bids.where(:product_id => self.id).max(:bid_amount) : 0.0
        end
        return {
                    :id => self.id.to_s,
                    :product_name => self.product_name,
                    :uploaded_by_name => self.user.blank? ? "" : self.user.full_name,
                    :uploaded_by_id => self.user.blank? ? "" : self.user.id.to_s,
                    :uploaded_in => self.user.my_location,
                    :uploaded_by_image => self.user.avatar.blank? ? "" : "#{self.user.avatar.url}",
                    :user_is_premium => self.user.is_premium == true ? 1 : 0,
                    :product_image => self.product_images.reject{|i| (i.image_upload.blank? || i.image_upload.to_s.ends_with?("_old_")) }.count > 0 ? simplified_images(self.product_images.reject{|i| (i.image_upload.blank? || i.image_upload.to_s.ends_with?("_old_")) }.first, device_width) : "",
                    :product_description => self.product_description,
                    :bill_included => self.bill_included,
                    :min_bid_price => self.min_bid_price,
                    :buy_now_price => self.buy_now_price,
                    :latest_bid => self.bids.where(:bid_amount.gt => 0.0).count > 0 ? self.bids.max(:bid_amount) : 0,
                    :views_count => self.product_views.count,
                    :bids_count => self.bids.where(:bid_amount.gt => 0.0).count,
                    :comments_count => self.comments.count,
                    :saved_count => SavedShapp.where(:product_id => self.id).count,
                    :is_fav => SavedShapp.where(:product_id => self.id, :user_id => user.id).count > 0 ? 1 : 0,
                    :images => self.product_images.reject{|i| (i.image_upload.blank? || i.image_upload.to_s.ends_with?("_old_")) }.map{|img| simplified_images(img, device_width)},
                    :bidder_images => self.bids.limit(3).where(:bid_amount.gt => 0.0).to_a.map{|bid| bid.user.profileimage_path},
                    :my_bid => user_max_bid_on_product,
                    :bid_closed => self.bid_closed? == true ? 1 : 0,
                    :bid_start => self.bid_start.blank? ? "" : self.bid_start,
                    :bid_end => self.bid_end.blank? ? "" : self.bid_end,
                    :rated_by_user => self.product_ratings.where(:rated_by_id => user.id).count > 0 ? 1 : 0,
                    :ratings => self.product_rating,
                    :is_sold => self.sold_to_id.blank? ? 0 : 1,
                    :sold_to_user => self.sold_to.blank? ? 0 : (self.sold_to.id.to_s == user.id.to_s ? 1 : 0),
                    :latitude => self.latitude.blank? ? 0.0 : self.latitude,
                    :longitude => self.longitude.blank? ? 0.0 : self.longitude,
                    :video_upload => self.product_video.blank? ? "" : self.product_video.mp4.url,
                    :video_thumb => self.product_images.reject{|i| (i.image_upload.blank? || i.image_upload.to_s.ends_with?("_old_")) }.count > 0 ? simplified_images(self.product_images.reject{|i| (i.image_upload.blank? || i.image_upload.to_s.ends_with?("_old_")) }.first, device_width) : "",
                    :uploaded_by_location => self.user.my_location,
                    :category_id => self.category.blank? ? "" : self.category.id.to_s,
                    :category_name => self.category.blank? ? "" : self.category.name
                }
    end

    def to_chat(device_width, item_type)
        user = User.find(self.sold_to_id.to_s)
        puts "ID: #{self.id.to_s}"
        return {
                    :id => self.id.to_s,
                    :product_name => self.product_name,
                    :uploaded_by_name => item_type == "sold" ? self.sold_to.full_name : self.user.full_name,
                    :uploaded_by_id => self.user.id.to_s,
                    :uploaded_in => self.user.my_location,
                    :uploaded_by_image => self.user.avatar.blank? ? (self.product_images.count > 0 ? simplified_images(self.product_images.first, device_width) : "") : "#{self.user.avatar.url}",
                    :sold_to_id => self.sold_to_id.to_s,
                    :full_name => self.sold_to.full_name,
                    :sold_to_name => User.find(self.sold_to_id).full_name,
                    :product_image => self.product_images.count > 0 ? simplified_images(self.product_images.first, device_width) : "",
                    :is_online => RedisServer.instance.subscribed?(self, item_type == "sold" ? user : self.user) ? 1 : 0
                }
    end

    def bids_to_api
        return self.bids.order_by(:created_at => 'desc').where(:bid_amount.gt => 0.0).order_by(:bid_amount => 'desc').map{|bid| bid.to_api }
    end

    def product_rating
        if self.product_ratings.count > 0
            return self.product_ratings.map(&:rating).sum / self.product_ratings.count
        else
            return 0
        end
    end

    def simplified_images(product_image, device_width)
        return product_image.image_upload.blank? ? "" : "#{product_image.image_upload.url}"
    end

    def simplified_video_images(product, device_width)
        if device_width.to_i == 300
            return "#{product.product_video.url}"
        elsif device_width.to_i == 355
            return "#{product.product_video.url}"
        elsif device_width.to_i == 394
            return "#{product.product_video.url}"
        elsif device_width.to_i == 748
            return "#{product.product_video.url}"
        else
            return "#{product.product_video.url}"
        end
    end
end
