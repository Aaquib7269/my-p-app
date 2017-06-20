class User
    include Common
    include Mongo::Followable::Followed
    include Mongo::Followable::Follower
    include Mongo::Followable::History

    field :first_name, type: String
    field :last_name, type: String
    field :email_address, type: String
    field :phone_number, type: String
    field :encrypted_password, type: String
    field :avtar, type: String
    field :is_active, type: Mongoid::Boolean, :default => false
    field :push_notification, type: Mongoid::Boolean, :default => false
    field :auto_refresh, type: Mongoid::Boolean, :default => false
    field :email_notification, type: Mongoid::Boolean, :default => false
    field :longitude, type: Float
    field :latitude, type: Float
    field :country, type: String
    field :city, type: String
    field :channel_key, type: String
    field :api_key, type: String
    field :is_premium, type: Mongoid::Boolean, :default => false
    field :fb_id, type: String
    field :images_left, type: Integer, :default => 0
    field :videos_left, type: Integer, :default => 0
    field :language_selected, type: Integer, :default => 0

    mount_uploader :avatar, ProductimageUploader

    attr_accessor :password

    belongs_to :country, :class_name => "Country", :index => true, :inverse_of => :country
    belongs_to :state, :class_name => "State", :index => true, :inverse_of => :state
    belongs_to :city, :class_name => "City", :index => true, :inverse_of => :city

    has_many :bids, :dependent => :destroy
    has_many :notifications, :dependent => :destroy
    has_many :products, :dependent => :destroy
    has_many :favourites, :dependent => :destroy
    has_many :rejected_products, :dependent => :destroy
    has_many :saved_shapps, :dependent => :destroy
    has_many :user_ratings, :dependent => :destroy
    has_many :user_devices, :dependent => :destroy
    has_many :user_purchases, :dependent => :destroy
    has_many :product_reports, :dependent => :destroy

    has_one :search_profile

    validates_presence_of :first_name, :message => "First name is required"
    validates_presence_of :last_name, :message => "Last name is required"
    validates_presence_of :email_address, :message => "Email address is required"
    validates_format_of :email_address,:with => Devise::email_regexp, :message => "Email not in proper format"
    validates_uniqueness_of :email_address, :message => "Email address not available"
    validates_uniqueness_of :fb_id, :message => "Facebook ID not available", :allow_blank => true, :allow_nil => true

    before_create do |user|
        generate_channel_key
        user.api_key = user.generate_api_key
    end

    after_create do |user|
        EmailJob.new.send_welcome_email_to(user.email_address)
    end

    before_save do
        if !self.password.blank?
            key = "49f9ceb472a7c3d24bb3fd38f6e1647d13c01d2e8ed03a72230c4641dabff0789f89a4cae83823378277138579d945a4733c24903e90201f8c1059947338e2b5"
            crypt = ActiveSupport::MessageEncryptor.new(key)
            self.encrypted_password = crypt.encrypt_and_sign(self.password)
        end
    end

    def self.search(search)
        if search
            any_of({:first_name => /^#{search}/i}, {:last_name => /^#{search}/i}, {:email_address => /^#{search}/i})
        end
    end

    def my_location
        return "#{self.country.blank? ? "" : self.country.name}#{self.city.blank? ? "" : ", #{self.city.name}"}"
    end

    def to_api
        search_profile = self.search_profile
        if search_profile.blank?
            search_profile = SearchProfile.create(:user => self, :show_all => true, :category => nil, :quality => nil, :radius => 0, :price_range => 0.0)
        end
        return {
            :id => self.id.to_s,
            :first_name => self.first_name,
            :last_name => self.last_name,
            :email_address => self.email_address,
            :full_name => self.full_name,
            :push_notification => self.push_notification == true ? 1 : 0,
            :auto_refresh => self.auto_refresh == true ? 1 : 0,
            :email_notification => self.email_notification == true ? 1 : 0,
            :longitude => self.longitude,
            :latitude => self.latitude,
            :channel_key => self.channel_key,
            :api_key => self.api_key,
            :is_premium => self.is_premium == true ? 1 : 0,
            :fb_id => self.fb_id,
            :avatar => self.avatar.blank? ? "" : "#{self.avatar.url}",
            :phone_number => self.phone_number.blank? ? "" : self.phone_number,
            :category_id => search_profile.category.blank? ? "" : search_profile.category_id.to_s,
            :category_name => search_profile.category.blank? ? "" : search_profile.category.name,
            :quality_id => search_profile.quality.blank? ? "" : search_profile.quality_id.to_s,
            :quality_name => search_profile.quality.blank? ? "" : search_profile.quality.name,
            :show_all => search_profile.show_all == true ? 1 : 0,
            :radius => search_profile.radius,
            :price_range => search_profile.price_range.blank? ? 0 : search_profile.price_range,
            :country_id => self.country_id.blank? ? "" : self.country_id.to_s,
            :country_name => self.country.blank? ? "" : self.country.name,
            :state_id => self.state_id.blank? ? "" : self.state_id.to_s,
            :state_name => self.state.blank? ? "" : self.state.name,
            :city_id => self.city_id.blank? ? "" : self.city_id.to_s,
            :city_name => self.city.blank? ? "" : self.city.name,
            :images_left => self.images_left,
            :ratings => self.my_ratings,
            :videos_left => self.videos_left,
            :is_active => self.is_active == true ? 1 : 0
        }
    end

    def details_to_api(apiuser)
        return {
                    :id => self.id.to_s,
                    :full_name => self.full_name,
                    :products_count => self.products.count,
                    :followers_count => self.followers_count,
                    :following_count => self.followees_count,
                    :is_following => self.followee_of?(apiuser),
                    :bids_count => self.bids.map(&:product_id).uniq.count,
                    :avatar => self.avatar.blank? ? "" : "#{self.avatar.url}",
                    :products_data => [],
                    :is_premium => self.is_premium == true ? 1 : 0,
                    :location => self.my_location,
                    :rated_by_user => self.user_ratings.where(:rated_by_id => apiuser.id).count > 0 ? 1 : 0,
                    :ratings => self.my_ratings,
                    :is_online => 0,
                }
    end

    def to_chat(product)
        return {
                    :id => self.id.to_s,
                    :is_online => RedisServer.instance.subscribed?(product, self) ? 1 : 0,
                    :avatar => self.avatar.blank? ? "" : "#{self.avatar.url}",
                }
    end

    def generate_api_key
        loop do
            token = SecureRandom.base64.tr('+/=', 'Qrt')
            break token unless User.where(:api_key => token).exists?
        end
    end

    def generate_channel_key
        begin
            key = SecureRandom.urlsafe_base64
        end while User.where(:channel_key => key).exists?
        self.channel_key = key
    end

    def full_name
        if self.first_name.blank? && self.last_name.blank?
            "#{self.email}"
        elsif self.last_name.blank?
            "#{self.first_name.capitalize}"
        else
            "#{self.first_name.capitalize} #{self.last_name.capitalize}"
        end
    end

    def profileimage_path
        if self.avatar.blank?
            return self.avatar.url
        else
            return "#{self.avatar.url}"
        end
    end

    def my_ratings
        if self.user_ratings.count > 0
            return self.user_ratings.map(&:rating).sum / self.user_ratings.count
        else
            return 0
        end
    end
end
