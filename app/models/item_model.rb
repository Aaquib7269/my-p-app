class ItemModel
  	include Mongoid::Document
  	
  	field :name, type: String
  	field :is_enabled, type: Mongoid::Boolean, :default => false
  	belongs_to :brand, :class_name => "Brand", :index => true, :inverse_of => :brand

 	def self.search(search)
        if search
            any_of({:name => /#{search}/i})
        end
    end

    def to_api
    	return {:id => self.id.to_s, :name => self.name}
    end
end