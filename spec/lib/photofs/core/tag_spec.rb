require 'photofs/core/tag'
require 'photofs/core/image'

describe PhotoFS::Core::Tag do
  let(:name) { 'kawaguchiko' }

  it "should include a name" do
    expect(PhotoFS::Core::Tag.new(name).name).to eq(name)
  end

  describe "#hash" do
    let(:left) { PhotoFS::Core::Tag.new name }
    let(:right) { PhotoFS::Core::Tag.new(name * 2) }

    it "should return a fixnum" do
      expect(left.hash.is_a? Fixnum).to be true
    end

    it "should be the same for tags with the same name" do
      expect(left.hash).to eq(PhotoFS::Core::Tag.new(name).hash)
    end

    it "should be different for tags with different names" do
      expect(left.hash).not_to eq(right.hash)
    end
  end

  describe "#==" do
    let(:left) { PhotoFS::Core::Tag.new(name) }

    context "other is not a tag" do
      let(:right) { 'an other' }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other does not have the same name" do
      let(:right) { PhotoFS::Core::Tag.new(left.name * 2) }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other is an tag with same name" do
      let(:right) { PhotoFS::Core::Tag.new('') }

      before(:each) do
        allow(right).to receive(:name).and_return(left.name)
      end

      it "should be true" do
        expect(left == right). to be true
      end
    end
  end

  describe :remove do
    let(:image_a) { PhotoFS::Core::Image.new('a') }
    let(:image_b) { PhotoFS::Core::Image.new('b') }
    let(:image_c) { PhotoFS::Core::Image.new('c') }
    let(:tag) { PhotoFS::Core::Tag.new('tag') }
    let(:all_images) { [image_a, image_b, image_c] }
    let(:first_two_images) { [image_a, image_b] }

    context 'when the tag contains many images' do
      before(:example) do
        all_images.each { |i| tag.add i }        
      end

      it 'should remove images from this tag' do
        expect(tag.remove(first_two_images).to_a).to contain_exactly(image_c)
      end

      it 'should remove individual images passed as a non-array argument' do
        expect(tag.remove(image_c).to_a).to contain_exactly(*first_two_images)
      end
    end

    it 'should return the tag' do
      expect(tag.remove first_two_images).to be(tag)
    end
  end # :remove
end
