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

end
