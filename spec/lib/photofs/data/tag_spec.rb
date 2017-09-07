require 'photofs/core/tag'
require 'photofs/data/tag'

describe PhotoFS::Data::Tag, type: :model do
  let(:klass) { PhotoFS::Data::Tag }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should have_many(:images).through(:tag_bindings) }

  describe :new_from_tag do
    let(:image1) { instance_double("PhotoFS::Core::Image", :path => '/foo/bar.jpg') }
    let(:image2) { instance_double("PhotoFS::Core::Image", :path => '/foo/bar2.jpg') }
    let(:tag) { instance_double("PhotoFS::Core::Tag", :name => 'せいかつ', :images => [image1, image2]) }
    let(:image_record_1) { build :image }
    let(:image_record_2) { build :image }

    before(:example) do
      allow(PhotoFS::Data::Image).to receive(:from_images).with([tag.images[0], tag.images[1]]).and_return([image_record_1,image_record_2])
    end

    it 'should copy the name' do
      expect(klass.new_from_tag(tag).name).to eq(tag.name)
    end

    it 'should be a new record' do
      expect(klass.new_from_tag(tag).new_record?).to be true
    end

    it 'should create a tag binding for each image in the tag' do
      expect(klass.new_from_tag(tag).images).to contain_exactly(image_record_1, image_record_2)
    end
  end # :new_from_tag

  describe :consistent_with? do
    context 'when the name and tag bindings match' do
      let(:tag_record) { build :tag_with_image }
      let(:tag_object) { instance_double("PhotoFS::Core::Tag", :name => tag_record.name, :images => []) }

      before(:example) do
        allow(PhotoFS::Data).to receive(:consistent_arrays?).and_return(true)
      end

      it 'should be true' do
        expect(tag_record.consistent_with? tag_object).to be true
      end
    end

    context 'when the name does not match' do
      let(:tag_record) { build :tag }
      let(:tag_object) { instance_double("PhotoFS::Core::Tag", :name => tag_record.name * 2) }

      it 'should be false' do
        expect(tag_record.consistent_with? tag_object).to be false
      end
    end

    context 'when the tag bindings do not match' do
      let(:tag_record) { build :tag_with_image }
      let(:tag_object) { instance_double("PhotoFS::Core::Tag", :name => tag_record.name, :images => []) }

      before(:example) do
        allow(PhotoFS::Data).to receive(:consistent_arrays?).and_return(false)
      end

      it 'should be false' do
        expect(tag_record.consistent_with? tag_object).to be false
      end
    end
  end # :consistent_with?

  describe :to_simple do
    let(:tag_record) { build :tag_with_image }
    let(:image_objects) { tag_record.images.map { |i| i.to_simple } }

    before(:example) do
      tag_record.images << (create :image)
    end

    it 'should return a simple object with an image for each of the associated image records' do
      expect(tag_record.to_simple.images).to contain_exactly(*image_objects)
    end
  
    it 'should return a simple object with the same name' do
      expect(tag_record.to_simple.name).to eq tag_record.name
    end
  end

  describe :update_from do
    let(:image1) { instance_double("PhotoFS::Core::Image", :path => '/foo/bar.jpg') }
    let(:image2) { instance_double("PhotoFS::Core::Image", :path => '/foo/bar2.jpg') }
    let(:image3) { instance_double("PhotoFS::Core::Image", :path => '/foo/bar3.jpg') }
    let(:tag) { instance_double("PhotoFS::Core::Tag", :name => 'せいかつ', :images => [image1, image2]) }
    let(:tag_record) { build :tag }
    let(:image_record_1) { build :image }
    let(:image_record_2) { build :image }
    let(:image_record_3) { build :image }

    before(:example) do
      tag_record.images << image_record_1
      tag_record.images << image_record_2
    end

    context 'when there exists a new image in the tag' do
      before(:example) do
        allow(PhotoFS::Data::Image).to receive(:from_images).with([image1, image2, image3]).and_return([image_record_1, image_record_2, image_record_3])
        allow(tag).to receive(:images).and_return(tag.images + [image3])
      end

      it 'will add a corresponding tag binding' do
        expect(tag_record.update_from(tag).images).to contain_exactly(image_record_1, image_record_2, image_record_3)
      end
    end

    context 'when an image is missing' do
      before(:example) do
        allow(PhotoFS::Data::Image).to receive(:from_images).with([image1, image2]).and_return([image_record_1, image_record_2])

        tag_record.images << image_record_3
      end

      it 'will remove the corresponding tag binding' do
        expect(tag_record.update_from(tag).images).to contain_exactly(image_record_1, image_record_2)
      end
    end
  end # :update_from

end
