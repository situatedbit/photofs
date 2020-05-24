require 'photofs/core/tag'
require 'photofs/data/tag'

describe PhotoFS::Data::Tag, type: :model do
  let(:tag_class) { PhotoFS::Data::Tag }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should have_many(:images).through(:tag_bindings) }

  describe :new_from_tag do
    let(:image1) { instance_double("PhotoFS::Core::Image", path: '/foo/bar.jpg') }
    let(:image2) { instance_double("PhotoFS::Core::Image", path: '/foo/bar2.jpg') }
    let(:tag) { instance_double("PhotoFS::Core::Tag", name: 'せいかつ', images: [image1, image2]) }
    let(:image_record_1) { build :image }
    let(:image_record_2) { build :image }

    before(:example) do
      allow(PhotoFS::Data::Image).to receive(:from_images).with([tag.images[0], tag.images[1]]).and_return([image_record_1,image_record_2])
    end

    it 'should copy the name' do
      expect(tag_class.new_from_tag(tag).name).to eq(tag.name)
    end

    it 'should be a new record' do
      expect(tag_class.new_from_tag(tag).new_record?).to be true
    end

    it 'should create a tag binding for each image in the tag' do
      expect(tag_class.new_from_tag(tag).images).to contain_exactly(image_record_1, image_record_2)
    end
  end # :new_from_tag

  describe :consistent_with? do
    context 'when the name and tag bindings match' do
      let(:tag_record) { build :tag_with_image }
      let(:tag_object) { instance_double("PhotoFS::Core::Tag", name: tag_record.name, images: []) }

      before(:example) do
        allow(PhotoFS::Data).to receive(:consistent_arrays?).and_return(true)
      end

      it 'should be true' do
        expect(tag_record.consistent_with? tag_object).to be true
      end
    end

    context 'when the name does not match' do
      let(:tag_record) { build :tag }
      let(:tag_object) { instance_double("PhotoFS::Core::Tag", name: tag_record.name * 2) }

      it 'should be false' do
        expect(tag_record.consistent_with? tag_object).to be false
      end
    end

    context 'when the tag bindings do not match' do
      let(:tag_record) { build :tag_with_image }
      let(:tag_object) { instance_double("PhotoFS::Core::Tag", name: tag_record.name, images: []) }

      before(:example) do
        allow(PhotoFS::Data).to receive(:consistent_arrays?).and_return(false)
      end

      it 'should be false' do
        expect(tag_record.consistent_with? tag_object).to be false
      end
    end
  end # :consistent_with?

  describe :recently_applied do
    context 'when limit is less than 0' do
      before(:example) do
        create :tag_with_image
      end

      it 'is empty' do
        expect(tag_class.recently_applied(-1)).to be_empty
      end
    end

    context 'when there are no tags' do
      it { expect(tag_class.recently_applied).to be_empty }
    end

    context 'when there have been fewer tags applied than the limit' do
      let!(:tags) do
        (1..5).map { create(:tag_with_image).to_simple }
      end

      it 'is those tags' do
        expect(tag_class.recently_applied(6)).to match_array(tags)
      end
    end

    it 'ignores non-unique tag applications' do
      tree = create :tag_with_image, name: 'tree'

      shrub = create :tag_with_image, name: 'shrub'
      create :tag_binding, tag: shrub

      expect(tag_class.recently_applied(2)).to contain_exactly(shrub.to_simple, tree.to_simple)
    end

    it 'is the most recently applied tags' do
      tree_tag = create :tag_with_image, name: 'tree'

      # manually advance the tag created_at timestamp by seconds; by default
      # the ActiveRecord created_at is too low fidelity for this test to
      # pass.
      latest_tag_bindings = Array(1..5).map do |i|
        create :tag_binding, created_at: (tree_tag.created_at.advance(seconds: i))
      end

      latest_tags = latest_tag_bindings.map { |binding| binding.tag.to_simple }

      expected = tag_class.recently_applied(5)

      expect(expected).to match_array(latest_tags)
    end
  end

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
    let(:image1) { instance_double("PhotoFS::Core::Image", path: '/foo/bar.jpg') }
    let(:image2) { instance_double("PhotoFS::Core::Image", path: '/foo/bar2.jpg') }
    let(:image3) { instance_double("PhotoFS::Core::Image", path: '/foo/bar3.jpg') }
    let(:tag) { instance_double("PhotoFS::Core::Tag", name: 'せいかつ', images: [image1, image2]) }
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
