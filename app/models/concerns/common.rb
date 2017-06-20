module Common
	extend ActiveSupport::Concern

	included do
		include Mongoid::Document
		include Mongoid::Timestamps::Created
    	include Mongoid::Timestamps::Updated
    	include ActionView::Helpers::NumberHelper
    	include Rails.application.routes.url_helpers
	end

	def formatted_created_at
		self.created_at.strftime("%I:%M %P, %d %B %Y")
	end
end
