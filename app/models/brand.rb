class Brand
  	include Common

  	field :name, type: String
  	belongs_to :category, :class_name => "Category", :index => true, :inverse_of => :category

  	has_many :item_models
  	accepts_nested_attributes_for :item_models, :reject_if => :all_blank, :allow_destroy => true

  	def self.search(search)
        if search
            any_of({:name => /#{search}/i})
        end
    end

    def to_api
    	return {:id => self.id.to_s, :name => self.name, :has_models => self.item_models.count}
    end
end
