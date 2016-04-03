require 'photofs/data/image'
require 'photofs/core/image'

describe PhotoFS::Data::Image, type: :model do
  let(:klass) { PhotoFS::Data::Image }

  it { should validate_presence_of(:image_file) }
  it { should validate_uniqueness_of(:image_file_id) }

  describe :from_image do
    let(:image_record) { create :image }
    let(:image) { image_record.to_simple }

    it 'should be an image record' do
      expect(klass.from_image image).to be_an_instance_of(klass)
    end
  end

  describe 'class :new_from_image' do
    let(:image) { PhotoFS::Core::Image.new('some-path') }
    let(:file) { build(:file) }

    before(:example) do
      allow(PhotoFS::Data::File).to receive(:new).with({:path => image.path}).and_return(file)
    end

    it 'should have a file with the image path' do
      expect(klass.new_from_image(image).image_file).to be file
    end

    it 'should not be saved' do
      expect(klass.new_from_image(image).new_record?).to be true
    end
  end # :new_from_image

  describe :consistent_with? do
    let(:record) { build :image }
    let(:image) { instance_double('PhotoFS::Core::Image') }

    context 'when the path matches jpeg file path' do
      before(:example) do
        allow(image).to receive(:path).and_return(record.image_file.path)
      end

      it 'should be true' do
        expect(record.consistent_with? image).to be true
      end
    end

    context 'when paths do not match' do
      before(:example) do
        allow(image).to receive(:path).and_return(record.image_file.path + '違う')
      end

      it 'should be false' do
        expect(record.consistent_with? image).to be false
      end
    end
  end # :consistent_with?

  describe :update_from do
    let(:record) { build :image }

    context 'when the path is the same' do
      let(:image) { instance_double('PhotoFS::Core::Image', :path => record.image_file.path) }

      it 'will not update path' do
        expect(record).not_to receive(:build_image_file)

        record.update_from image
      end
    end

    context 'when the path does not match' do
      let(:different_path) { record.image_file.path + '/違う' }
      let(:image) { instance_double('PhotoFS::Core::Image', :path => different_path) }

      it 'sets image_file to new file from path' do
        expect(record).to receive(:build_image_file).with(hash_including(:path => different_path))

        record.update_from image
      end
    end
  end # :update_from
end
