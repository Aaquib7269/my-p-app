# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base
    include CarrierWave::RMagick
  
    storage :file
    
    def store_dir
        "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    def default_url(*args)
    	ActionController::Base.helpers.asset_path("app/avatar.png")
  	end
end
