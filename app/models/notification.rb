class Notification
    include Common

    field :notification_string, type: String
    field :notification_type, type: Integer
    field :action, type: String
    field :item_id, type: String
    field :item_image, type: String

    belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user

    def to_api
        return {
                    :id => self.id.to_s,
                    :created_at => self.created_at,
                    :notification_string => self.notification_string,
                    :notification_type => self.notification_type,
                    :action => self.action.blank? ? "" : self.action,
                    :item_id => self.item_id.blank? ? "" : self.item_id,
                    :item_image => self.item_image.blank? ? "" : self.item_image
                }
    end
end
