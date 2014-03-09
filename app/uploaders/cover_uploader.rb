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

end
