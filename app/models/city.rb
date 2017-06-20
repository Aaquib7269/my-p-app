class City
  	include Common
  
  	field :name, type: String
  	field :default_id, type: Integer
  	belongs_to :state, :class_name => "State", :index => true, :inverse_of => :state

  	def self.search(search)
        if search
            any_of({:name => /#{search}/i})
        end
    end

    def to_api
    	return {:id => self.id.to_s, :state_id => self.state_id.to_s, :name => self.name}
    end
end
