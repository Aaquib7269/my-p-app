class ProductView
  	include Common

  	field :ip_address, type: String
  	belongs_to :product, :class_name => "Product", :inverse_of => :product
end
