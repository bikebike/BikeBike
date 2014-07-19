# encoding: utf-8
require 'carrierwave/processing/mini_magick'

class CoverUploader < CarrierWave::Uploader::Base

	include CarrierWave::ImageOptimizer
	include CarrierWave::MiniMagick

	storage :file
	process :optimize

	def store_dir
		"uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
	end

	version :preview do
		process :resize_to_fit => [480, 240]
	end

	version :full do
		process :resize_to_fit => [1200, 800]
	end

	def image
		@image ||= MiniMagick::Image.open(file.path)
	end

	def is_landscape?
		image['width'] > image['height']
	end

	def manipulate!
		cache_stored_file! if !cached?
		image = ::MiniMagick::Image.open(current_path)

		begin
			image.format(@format.to_s.downcase) if @format
			image = yield(image)
			image.write(current_path)
			begin
				image.run_command("identify", current_path)
			rescue
				image.run_command("identify", '"' + current_path + '"')
			end
		ensure
			image.destroy!
		end
	rescue ::MiniMagick::Error, ::MiniMagick::Invalid => e
		default = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e, :locale => :en)
		message = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e, :default => default)
		raise CarrierWave::ProcessingError, message
	end

end
