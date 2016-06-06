require 'photofs/core/tag'
require 'photofs/core/tag_set'
require 'photofs/core/image'

describe PhotoFS::Core::TagSet do
  let(:name) { 'ほっかいど' }
  let(:tag_set) { PhotoFS::Core::TagSet.new }
  let(:tags) { Hash.new }

  before(:example) do
    allow(tag_set).to receive(:tags).and_return(tags)
  end

  describe "#add?" do
    let(:tag) { PhotoFS::Core::Tag.new 'test' }

    context 'when tag is already in the set' do
      before(:example) do
        allow(tags).to receive(:has_key?).with(tag.name).and_return(true)
      end

      it 'should return nil' do
        expect(tag_set.add? tag).to be nil
      end

      it 'should not add tag to the set' do
        expect(tags).not_to receive(:[]=)

        tag_set.add? tag
      end
    end

    context 'when tag is not in the set' do
      before(:example) do
        allow(tags).to receive(:has_key?).with(tag.name).and_return(false)
      end

      it 'should return self' do
        expect(tag_set.add? tag).to be tag_set
      end

      it 'should add tag to the set' do
        expect(tags).to receive(:[]=).with(tag.name, tag)

        tag_set.add? tag
      end
    end
  end

  describe "#find_by_name" do
    let(:tag) { PhotoFS::Core::Tag.new name }

    context "passed a non-matching string" do
      it "it should return nil" do
        expect(tag_set.find_by_name 'garbage').to be nil
      end
    end

    context "passed a matching string" do
      let(:tags) { { tag.name => tag } }

      it "should return a tag" do
        expect(tag_set.find_by_name tag.name).to eq(tag)
      end
    end

    context "passed an empty array" do
      it "should return an empty array" do
        expect(tag_set.find_by_name []).to be_empty
      end
    end

    context "do passed an array of non-matching strings" do
      it "should return an empty array" do
        expect(tag_set.find_by_name ['garbage', 'trash']).to be_empty
      end
    end

    context "do passed an array of matching strings" do
      let(:tag2) { PhotoFS::Core::Tag.new(name * 2) }
      let(:search_tags) { [tag.name, tag2.name] }
      let(:tags) { {tag.name => tag, tag2.name => tag2} }

      it "should return an array of matching tags" do
        expect(tag_set.find_by_name search_tags).to contain_exactly(tag, tag2)
      end
    end
  end

  describe :find_by_images do
    let(:image_set) { PhotoFS::Core::ImageSet.new :set => [image].to_set }
    let(:image) { PhotoFS::Core::Image.new 'ちよだ' }
    let(:tag) { PhotoFS::Core::Tag.new 'タグ' }

    context "when there are no tags" do
      it "should return an empty collection" do
        expect(tag_set.find_by_images image_set).to be_empty
      end
    end

    context 'when there are no images' do
      before(:each) do
        tag.add image
        tag_set.add? tag
      end

      it { expect(tag_set.find_by_images PhotoFS::Core::ImageSet.new).to be_empty }
    end

    context "when passed a single image" do
      before(:each) do
        tag.add image
        tag_set.add? tag
      end

      it "should return the tags for that image" do
        expect(tag_set.find_by_images image_set).to contain_exactly(tag)
      end
    end

    context "when there are multiple images" do
      let(:image_set) { PhotoFS::Core::ImageSet.new :set => [image, image2].to_set }

      let(:image2) { PhotoFS::Core::Image.new '二.jpg' }
      let(:tag2) { PhotoFS::Core::Tag.new '三' }
      let(:tag3) { PhotoFS::Core::Tag.new '四' }

      before(:each) do
        [image, image2].each { |i| tag.add i }
        [image, image2].each { |i| tag2.add i }
        tag3.add image

        [tag, tag2, tag3].each { |t| tag_set.add? t }
      end

      it "should return the union of tags from those images" do
        expect(tag_set.find_by_images image_set).to contain_exactly(tag, tag2, tag3)
      end
    end
  end

  describe :intersection do
    let(:first) { PhotoFS::Core::Tag.new('first') }
    let(:second) { PhotoFS::Core::Tag.new('second') }
    let(:first_images) { [1, 2, 3].map { |i| PhotoFS::Core::Image.new(i.to_s) } }
    let(:second_images) { [3, 4, 5].map { |i| PhotoFS::Core::Image.new(i.to_s) } }

    before(:each) do    
      first_images.each { |i| first.add(i) }
      second_images.each { |i| second.add(i) }
    end

    it "should respond to an empty array with an empty set" do
      expect(PhotoFS::Core::TagSet.intersection([]).all).to be_empty
    end

    it "should return an empty set for tags that don't exist" do
      expect(PhotoFS::Core::TagSet.intersection([PhotoFS::Core::Tag.new('garbage')]).all).to be_empty
    end

    it "should do a simple find for an array of size one" do
      expect(PhotoFS::Core::TagSet.intersection([first]).all).to contain_exactly(*first_images)
    end

    it "should create an intersection set from the tags that are returned" do
      expect(PhotoFS::Core::TagSet.intersection([first, second]).all).to contain_exactly(PhotoFS::Core::Image.new('3'))
    end
  end

  describe '#delete' do
    let(:tag) { PhotoFS::Core::Tag.new 'test' }

    it 'proxies the delete call to internal hash storage' do
      expect(tags).to receive(:delete).with(tag.name)

      tag_set.delete tag
    end
  end

  describe :limit_to_images do
    subject { tag_set.limit_to_images image_set }

    let(:image1) { instance_double('Image', :name => '1.jpg') }
    let(:image2) { instance_double('Image', :name => '2.jpg') }
    let(:image3) { instance_double('Image', :name => '3.jpg') }
    let(:image4) { instance_double('Image', :name => '4.jpg') }
    let(:image_set) { PhotoFS::Core::ImageSet.new(:set => [image1, image2, image3].to_set) }

    let(:tag1) { PhotoFS::Core::Tag.new 'good', :set => [image1, image2, image4].to_set }
    let(:tag2) { PhotoFS::Core::Tag.new 'bad', :set => [image1].to_set }
    let(:tag3) { PhotoFS::Core::Tag.new 'ugly' }

    before(:each) do
      [tag1, tag2, tag3].each { |t| tag_set.add? t }
    end

    it 'should only contain tags that had images from the site' do
      expect(subject.all).to include(have_attributes(:name => 'good'), have_attributes(:name => 'bad'))
    end

    it 'should add previously tagged images to each tag' do
      expect(subject.find_by_name('good').images).to contain_exactly(image1, image2)
    end

    it { expect(subject).to be_an_instance_of(PhotoFS::Core::TagSet) }

    context 'when image set does not overlap with images in tags' do
      before(:each) do
        allow(tag_set).to receive(:find_by_images).and_return([])
      end

      it { expect(subject).to be_empty }
    end
  end

  describe :rename do
    let(:old_tag_images) { [instance_double('Image'), instance_double('Image')] }
    let(:old_tag) { instance_double('Tag', :name => 'old tag') }
    let(:new_tag) { instance_double('Tag', :name => 'new tag') }

    after(:example) do
      allow(new_tag).to receive(:add)
      allow(old_tag).to receive(:images).and_return(old_tag_images)

      tag_set.rename old_tag, new_tag
    end

    it 'should move all images from old tag to new tag' do
      expect(new_tag).to receive(:add).exactly(old_tag_images.size).times
    end

    it 'should add new tag to the set' do
      expect(tag_set).to receive(:add?).with(new_tag)
    end

    it 'should remove old tag from the set' do
      expect(tag_set).to receive(:delete).with(old_tag)
    end
  end # :rename
end
