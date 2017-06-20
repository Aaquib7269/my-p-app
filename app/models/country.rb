class Country
  	include Common
  
  	field :name, type: String
  	field :default_id, type: Integer
  	field :shortcode, type: String

  	def self.search(search)
        if search
            any_of({:name => /^#{search}/i}, {:shortcode => /^#{search}/i})
        end
    end

    def to_api
    	return {:id => self.id.to_s, :name => self.name, :shortcode => self.shortcode}
    end
end
