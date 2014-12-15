class LocalFileUploader < CarrierWave::Uploader::Base
  include FileUploader

  storage :file

  def store_dir
    Rails.root.join "files/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
