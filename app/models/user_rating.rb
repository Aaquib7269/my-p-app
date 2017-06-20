class UserRating
  include Common

  field :rating, type: Float

  belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
  belongs_to :rated_by, :class_name => "User", :index => true, :inverse_of => :rated_by
end
