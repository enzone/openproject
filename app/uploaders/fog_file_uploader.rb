class FogFileUploader < CarrierWave::Uploader::Base
  include FileUploader

  storage :fog
  attr_reader :remote_file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def local_file
    @remote_file = file
    cache_stored_file!
    super
  end

  def download_url
    remote_file.url
  end
end
