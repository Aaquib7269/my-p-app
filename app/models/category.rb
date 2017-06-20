class Category
	include Common

	field :name, type: String
	field :order, type: Integer

	has_many :brands, :dependent => :destroy
	has_many :sub_categories, :class_name => "Category", :foreign_key => "parent_category_id", :dependent => :destroy
	belongs_to :parent_category, :class_name => "Category", :index => true, :inverse_of => :parent_category

	def self.search(search)
        if search
            any_of({:name => /#{search}/i})
        end
    end

    def to_api
    	return {:id => self.id.to_s, :name => self.name, :has_brands => self.brands.count}
    end
end
