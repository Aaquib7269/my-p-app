class Quality
	include Common
	
	field :name, type: String
	field :order, type: Integer

	def self.search(search)
        if search
            any_of({:name => /#{search}/i})
        end
    end

    def to_api
    	return {:id => self.id.to_s, :name => self.name}
    end
end
