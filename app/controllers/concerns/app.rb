module App
  	
  	extend ActiveSupport::Concern

  	included do
  		before_filter :authenticate_admin!
    	layout 'app'
  	end
end