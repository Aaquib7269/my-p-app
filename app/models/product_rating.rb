class ProductRating
    include Common

    field :rating, type: Float

    belongs_to :product, :class_name => "Product", :index => true, :inverse_of => :product
    belongs_to :rated_by, :class_name => "User", :index => true, :inverse_of => :rated_by
end
