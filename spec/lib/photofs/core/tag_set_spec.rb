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

  describe "#find_by_image" do
    let(:image) { PhotoFS::Core::Image.new 'ちよだ' }
    let(:tag) { PhotoFS::Core::Tag.new 'タグ' }

    context "when there are no tags" do
      before(:each) do
        allow(tag_set).to receive(:image_tags_hash).and_return({})
      end

      it "should return an empty collection" do
        expect(tag_set.find_by_image image).to be_empty
      end
    end

    context "when passed a single image" do
      before(:each) do
        allow(tag_set).to receive(:image_tags_hash).and_return({ image => [tag] })
      end

      it "should return the tags for that image" do
        expect(tag_set.find_by_image image).to contain_exactly(tag)
      end
    end

    context "when there are multiple images" do
      let(:image2) { 'image2' }
      let(:tag2) { 'tag2' }
      let(:tag3) { 'tag3' }

      before(:each) do
        hash = { image => [tag, tag2], image2 => [tag2, tag3] }
        allow(tag_set).to receive(:image_tags_hash).and_return(hash)
      end

      it "should return the union of tags from those images" do
        expect(tag_set.find_by_image [image, image2]).to contain_exactly(tag, tag2, tag3)
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

  describe "#image_tags_hash" do
    context "when there are no images" do
      let :tags do
        Hash[ ['a', 'b', 'c'].map { |n| [n, PhotoFS::Core::Tag.new(n)] } ]
      end

      it "should be empty" do
        expect(tag_set.send :image_tags_hash).to be_empty
      end
    end

    context "when there are no tags" do
      let(:tags) { Hash.new }

      it "should be empty" do
        expect(tag_set.send :image_tags_hash).to be_empty
      end
    end

    context "when there are images with multiple tags" do
      let(:tag1) { PhotoFS::Core::Tag.new('a') }
      let(:tag2) { PhotoFS::Core::Tag.new('b') }
      let(:tag3) { PhotoFS::Core::Tag.new('c') }

      let(:image1) { PhotoFS::Core::Image.new('1') }
      let(:image2) { PhotoFS::Core::Image.new('2') }
      let(:image3) { PhotoFS::Core::Image.new('3') }

      let(:tags) do
        { tag1.name => tag1, tag2.name => tag2, tag3.name => tag3 }
      end

      before(:each) do
        allow(tag1).to receive(:images).and_return([image1, image2])
        allow(tag2).to receive(:images).and_return([image2, image3])
        allow(tag3).to receive(:images).and_return([image3])
      end

      it "should flip keys and values" do
        expect((tag_set.send :image_tags_hash)[image1]).to contain_exactly(tag1)
        expect((tag_set.send :image_tags_hash)[image2]).to contain_exactly(tag1, tag2)
        expect((tag_set.send :image_tags_hash)[image3]).to contain_exactly(tag2, tag3)
      end
    end
  end

  describe '#delete' do
    let(:tag) { PhotoFS::Core::Tag.new 'test' }

    it 'proxies the delete call to internal hash storage' do
      expect(tags).to receive(:delete).with(tag.name)

      tag_set.delete tag
    end
  end
end
