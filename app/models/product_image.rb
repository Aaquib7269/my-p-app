class ProductImage
  	include Mongoid::Document
  	mount_uploader :image_upload, ProductimageUploader
  	belongs_to :product, :class_name => "Product", :index => true, :inverse_of => :product

  	def image_path
        if self.image_upload.blank?
            return self.image_upload.url
        else
            return "#{self.image_upload.url}"
        end
    end
end
