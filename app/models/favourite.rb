class Favourite
  	include Common
  	belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
  	belongs_to :product, :class_name => "Product", :index => true, :inverse_of => :product
end
