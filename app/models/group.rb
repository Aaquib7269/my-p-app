class Group
    include Common
    include Mongo::Followable::Followed
    include Mongo::Followable::Follower
    include Mongo::Followable::History

    field :group_name, type: String
    field :is_active, type: Mongoid::Boolean
    field :group_type, type: String
    mount_uploader :group_image, GroupImageUploader
	has_many :group_requests, :dependent => :destroy
    belongs_to :admin, :class_name => "User", :index => true, :inverse_of => :admin
    has_many :admins, class_name: 'GroupAdmin', inverse_of: :admins, autosave: true
    has_many :users, class_name: 'GroupUser'

    def to_api(apiuser)
        return {
                    :id => self.id.to_s,
                    :group_name => self.group_name,
                    :admin_name => self.admin.blank? ? "" : self.admin.full_name,
                    :admin_location => self.admin.blank? ? "" : self.admin.my_location,
                    :admin_photo => self.admin.blank? ? "" : (self.admin.avatar.blank? ? "" : "#{self.admin.avatar.url}"),
                    :members_count => self.followers_count,
                    :products_count => Product.where(:group_id => self.id).count,
                    :followers_count => self.followers_count,
                    :in_group => (self.users.where(:user_id => apiuser.id).count > 0 || self.admin_id == apiuser.id) ? 1 : 0,
                    :created_at => self.created_at.strftime('%A %d %B, %Y'),
                    :user_is_admin => self.admin_id == apiuser.id ? 1 : 0,
                    :is_following => self.followers.where(:f_id => apiuser.id.to_s).count > 0 ? 1 : 0,
                    :group_image => self.group_image.blank? ? "" : "#{self.group_image.url}",
                    :group_type => self.group_type.blank? ? "open" : self.group_type
                }
    end

    def to_search
    	return {:id => self.id.to_s, :name => self.group_name}
    end
end
