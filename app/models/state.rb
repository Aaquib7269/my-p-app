class State
  	include Common
  
  	field :name, type: String
  	field :default_id, type: Integer
  	belongs_to :country, :class_name => "Country", :index => true, :inverse_of => :country

  	def self.search(search)
        if search
            any_of({:name => /#{search}/i})
        end
    end

    def to_api
    	return {:id => self.id.to_s, :country_id => self.country_id.to_s, :name => self.name}
    end

end
