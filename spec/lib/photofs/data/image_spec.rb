require 'photofs/data/image'
require 'photofs/core/image'

describe PhotoFS::Data::Image, type: :model do
  it { should validate_presence_of(:jpeg_file) }
  it { should validate_uniqueness_of(:jpeg_file_id) }

  describe :new_from_image do
    let(:image) { PhotoFS::Core::Image.new('some-path') }
    let(:file) { build(:file) }

    before(:example) do
      allow(PhotoFS::Data::File).to receive(:new).with({:path => image.path}).and_return(file)
    end

    it 'should have a file with the image path' do
      expect(PhotoFS::Data::Image.new_from_image(image).jpeg_file).to be file
    end

    it 'should not be saved' do
      expect(PhotoFS::Data::Image.new_from_image(image).new_record?).to be true
    end
  end # :new_from_image
end
