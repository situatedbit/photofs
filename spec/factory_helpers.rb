module FactoryHelpers
  def create_images(paths)
    paths.each { |path| create_image path }
  end

  def create_image(path)
    create(:image, :image_file => build(:file, :path => path))
  end
end
