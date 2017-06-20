# encoding: utf-8

class VideoUploader < CarrierWave::Uploader::Base

    include CarrierWave::Video
    include CarrierWave::Video::Thumbnailer

    storage :file

    process encode_video: [:mp4, audio_codec: "aac",:custom => "-strict experimental -q:v 5 -preset slow -g 30"]
    
    version :mp4 do
        def full_filename(for_file)
            super.chomp(File.extname(super)) + '.mp4'
        end
    end

    def png_name for_file, version_name
        %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.png}
    end

    # version :iphone_5 do
    #     process thumbnail: [{format: 'png', quality: 10, size: 320, square: true, strip: true, logger: Rails.logger}]
    #     def full_filename for_file
    #         png_name for_file, version_name
    #     end
    #     Rails.logger.info("Created")
    # end

    # version :iphone_6 do
    #     process thumbnail: [{format: 'png', quality: 10, size: 375, square: true, strip: true, logger: Rails.logger}]
    #     def full_filename for_file
    #         png_name for_file, version_name
    #     end
    # end

    # version :iphone_6p do
    #     process thumbnail: [{format: 'png', quality: 10, size: 414, square: true, strip: true, logger: Rails.logger}]
    #     def full_filename for_file
    #         png_name for_file, version_name
    #     end
    # end

    # version :ipad do
    #     process thumbnail: [{format: 'png', quality: 10, size: 768, square: true, strip: true, logger: Rails.logger}]
    #     def full_filename for_file
    #         png_name for_file, version_name
    #     end
    # end

    def store_dir
        "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
end
