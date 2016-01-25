require 'spec_helper'
require 'tag'
require 'image'

describe PhotoFS::Tag do
  let(:name) { 'kawaguchiko' }

  it "should include a name" do
    expect(PhotoFS::Tag.new(name).name).to eq(name)
  end

  describe :add do
    context 'when an image is added' do
      it 'should cause :images to include that image'
    end
  end

  describe "#hash" do
    let(:left) { PhotoFS::Tag.new name }
    let(:right) { PhotoFS::Tag.new(name * 2) }

    it "should return a fixnum" do
      expect(left.hash.is_a? Fixnum).to be true
    end

    it "should be the same for tags with the same name" do
      expect(left.hash).to eq(PhotoFS::Tag.new(name).hash)
    end

    it "should be different for tags with different names" do
      expect(left.hash).not_to eq(right.hash)
    end
  end

  describe "#==" do
    let(:left) { PhotoFS::Tag.new(name) }

    context "other is not a tag" do
      let(:right) { 'an other' }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other does not have the same name" do
      let(:right) { PhotoFS::Tag.new(left.name * 2) }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other is an tag with same name" do
      let(:right) { PhotoFS::Tag.new('') }

      before(:each) do
        allow(right).to receive(:name).and_return(left.name)
      end

      it "should be true" do
        expect(left == right). to be true
      end
    end
  end
end
