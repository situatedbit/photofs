require 'photofs/data/image'
require 'photofs/core/image'

describe PhotoFS::Data::Image, type: :model do
  let(:klass) { PhotoFS::Data::Image }

  it { should validate_presence_of(:path) }
  it { should validate_uniqueness_of(:path) }

  describe :from_image do
    let(:image_record) { create :image }
    let(:image) { image_record.to_simple }

    it 'should be an image record' do
      expect(klass.from_image image).to be_an_instance_of(klass)
    end
  end

  describe :find_by_path_parent do
    let(:i1) { create_image 'a/1.jpg' }
    let(:i2) { create_image 'a/2.jpg' }
    let(:i3) { create_image 'a-b/3.jpg' }
    let(:i4) { create_image 'a-b/c/4.jpg' }
    let!(:images) { [i1, i2, i3, i4] }

    it { expect(klass.find_by_path_parent '1.jpg').to be_empty }

    it { expect(klass.find_by_path_parent '').to contain_exactly(*images) }
    it { expect(klass.find_by_path_parent 'a').to contain_exactly(i1, i2) }
    it { expect(klass.find_by_path_parent 'a/').to contain_exactly(i1, i2) }
    it { expect(klass.find_by_path_parent 'a-b/').to contain_exactly(i3, i4) }

    it { expect(klass.find_by_path_parent '/').to be_empty }
  end

  describe 'class :new_from_image' do
    let(:path) { 'some-path' }
    let(:image) { PhotoFS::Core::Image.new path }

    it 'should have a file with the image path' do
      expect(klass.new_from_image(image).path).to eq path
    end

    it 'should not be saved' do
      expect(klass.new_from_image(image).new_record?).to be true
    end
  end # :new_from_image

  describe :consistent_with? do
    let(:record) { build :image }
    let(:image) { instance_double('PhotoFS::Core::Image') }

    context 'when the path matches path' do
      before(:example) do
        allow(image).to receive(:path).and_return(record.path)
      end

      it 'should be true' do
        expect(record.consistent_with? image).to be true
      end
    end

    context 'when paths do not match' do
      before(:example) do
        allow(image).to receive(:path).and_return(record.path + '違う')
      end

      it 'should be false' do
        expect(record.consistent_with? image).to be false
      end
    end
  end # :consistent_with?

  describe :update_from do
    let(:record) { build :image }

    let(:different_path) { record.path + '/違う' }
    let(:image) { instance_double('PhotoFS::Core::Image', path: different_path) }

    it 'sets new file from path' do
      record.update_from image

      expect(record.path).to eq different_path
    end
  end # :update_from
end
