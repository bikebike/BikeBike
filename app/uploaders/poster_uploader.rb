# encoding: utf-8
require 'carrierwave/processing/mini_magick'

class PosterUploader < CarrierWave::Uploader::Base

	include CarrierWave::ImageOptimizer
	include CarrierWave::MiniMagick

	storage :file
	process :optimize

	@@sizes = {:thumb => [120, 120], :icon => [48, 48], :preview => [360, 120], :full => [1024, 1024]}

	def store_dir
		"uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
	end

	version :thumb do
		process :resize_to_fill => @@sizes[:thumb]
	end

	version :icon do
		process :resize_to_fill => @@sizes[:icon]
	end

	version :preview do
		process :resize_to_fit => @@sizes[:preview]
	end

	version :full do
		process :resize_to_fit => @@sizes[:full]
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
			image.run_command("identify", Gem.win_platform? ? '"' + current_path + '"' : current_path)
		ensure
			image.destroy!
		end
	rescue ::MiniMagick::Error, ::MiniMagick::Invalid => e
		default = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e, :locale => :en)
		message = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e, :default => default)
		raise CarrierWave::ProcessingError, message
	end

end
