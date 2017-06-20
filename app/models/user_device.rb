class UserDevice
    include Common
    
    field :device_type, type: Integer
    field :push_enabled, type: Mongoid::Boolean
    field :push_token, type: String
    field :hardware_id, type: String

    belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
end
