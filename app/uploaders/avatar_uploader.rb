# encoding: utf-8
require 'carrierwave/processing/mini_magick'

class AvatarUploader < CarrierWave::Uploader::Base

	include CarrierWave::ImageOptimizer
	include CarrierWave::MiniMagick

	# Include RMagick or MiniMagick support:
	# include CarrierWave::RMagick
	# include CarrierWave::MiniMagick

	# Choose what kind of storage to use for this uploader:

	storage :file
	process :optimize

	@@sizes = {:thumb => [120, 120], :icon => [48, 48], :preview => [360, 120]}
	# storage :fog

	# Override the directory where uploaded files will be stored.
	# This is a sensible default for uploaders that are meant to be mounted:
	def store_dir
		"uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
	end

	# Provide a default URL as a default if there hasn't been a file uploaded:
	def default_url
	#	 # For Rails 3.1+ asset pipeline compatibility:
	#	 # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
	#
		#"/images/fallback/" + [version_name, "default.png"].compact.join('_')
		"http://placehold.it/" + (@@sizes[version_name] || [300, 300]).join('x')
	end

	# Process files as they are uploaded:
	# process :scale => [200, 300]
	#
	#def scale(width, height)
	#end

	# Create different versions of your uploaded files:
	version :thumb do
		process :resize_to_fill => @@sizes[:thumb]
	end

	version :icon do
		process :resize_to_fill => @@sizes[:icon]
	end

	version :preview do
		process :resize_to_fit => @@sizes[:preview]
	end

	# Add a white list of extensions which are allowed to be uploaded.
	# For images you might use something like this:
	# def extension_white_list
	#	 %w(jpg jpeg gif png)
	# end

	# Override the filename of the uploaded files:
	# Avoid using model.id or version_name here, see uploader/store.rb for details.
	# def filename
	#	 "something.jpg" if original_filename
	# end

	def image
		@image ||= MiniMagick::Image.open(file.path)
	end

	def is_landscape?
		image['width'] > (image['height'] * 1.25)
	end

	#def recreate_versions!(*versions)
	#	if !current_path.nil?
	#		current_path = "'" + (current_path || '') + "'"
	#	end
	#	super(*versions)
	#end

	def manipulate!
		cache_stored_file! if !cached?
		image = ::MiniMagick::Image.open(current_path)

		begin
			image.format(@format.to_s.downcase) if @format
			image = yield(image)
			image.write(current_path)
			image.run_command("identify", '"' + current_path + '"')
		ensure
			image.destroy!
		end
	rescue ::MiniMagick::Error, ::MiniMagick::Invalid => e
		default = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e, :locale => :en)
		message = I18n.translate(:"errors.messages.mini_magick_processing_error", :e => e, :default => default)
		raise CarrierWave::ProcessingError, message
	end

end
