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

  describe :consistent_with? do
    let(:record) { build :image }
    let(:image) { instance_double('PhotoFS::Core::Image') }

    context 'when the path matches jpeg file path' do
      before(:example) do
        allow(image).to receive(:path).and_return(record.jpeg_file.path)
      end

      it 'should be true' do
        expect(record.consistent_with? image).to be true
      end
    end

    context 'when paths do not match' do
      before(:example) do
        allow(image).to receive(:path).and_return(record.jpeg_file.path + '違う')
      end

      it 'should be false' do
        expect(record.consistent_with? image).to be false
      end
    end
  end # :consistent_with?

  describe :update_from do
    let(:record) { build :image }

    context 'when the path is the same' do
      let(:image) { instance_double('PhotoFS::Core::Image', :path => record.jpeg_file.path) }

      it 'will not update path' do
        expect(record).not_to receive(:build_jpeg_file)

        record.update_from image
      end
    end

    context 'when the path does not match' do
      let(:different_path) { record.jpeg_file.path + '/違う' }
      let(:image) { instance_double('PhotoFS::Core::Image', :path => different_path) }

      it 'sets jpeg_file to new file from path' do
        expect(record).to receive(:build_jpeg_file).with(hash_including(:path => different_path))

        record.update_from image
      end
    end
  end # :update_from
end
