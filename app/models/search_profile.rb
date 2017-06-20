class SearchProfile
  	include Common
  	
  	field :show_all, type: Mongoid::Boolean
  	field :radius, type: Integer
  	field :price_range, type: Float
  	
  	belongs_to :user, :class_name => "User", :index => true, :inverse_of => :user
  	belongs_to :category, :class_name => "Category", :index => true, :inverse_of => :category
  	belongs_to :quality, :class_name => "Quality", :index => true, :inverse_of => :quality
end
