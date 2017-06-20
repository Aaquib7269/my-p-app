class GroupInvite
  	include Common
  	belongs_to :group, :class_name => "Group", :index => true, :inverse_of => :group
    belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
end
