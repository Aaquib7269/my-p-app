class Comment
  	include Common

  	field :comment_text, type: String
  	field :show_on_app, type: Mongoid::Boolean

  	belongs_to :product, :class_name => "Product", :inverse_of => :product
  	belongs_to :user, :class_name => "User", :inverse_of => :user

    def to_api
        return {
                    :id => self.id.to_s,
                    :user_name => self.user.full_name,
                    :user_image => self.user.avatar.blank? ? "" : "#{self.user.avatar.url}",
                    :created_at => self.created_at,
                    :user_location => self.user.my_location,
                    :comment_text => self.comment_text
                }
    end
end
