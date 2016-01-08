require 'spec_helper'
require 'tag'
require 'image'

describe PhotoFS::Tag do
  let(:name) { 'kawaguchiko' }

  it "should include a name" do
    expect(PhotoFS::Tag.new(name).name).to eq(name)
  end
=begin
  describe '#add' do
    let(:tag) { PhotoFS::Tag.new name }
    let(:images) { [] }

    context 'when an image is added twice' do
      before(:example) do
        images.each { |i| tag.add(i
# workline!
      end

      it 'should only keep the last copy' do
      end
    end
  end
=end
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

  describe "#intersection" do
    let(:left) { PhotoFS::Tag.new('left') }
    let(:a) { PhotoFS::Image.new('a') }
    let(:b) { PhotoFS::Image.new('b') }
    let(:b2) { PhotoFS::Image.new('b') }
    let(:c) { PhotoFS::Image.new('c') }
    let(:right) { [b2, c] }

    before(:each) do
      allow(left).to receive(:images).and_return([a])
    end

    context "the parameter set is empty" do
      it "should return an empty set" do
        expect(left.intersection []).to be_empty
      end
    end

    context "the base set is empty" do
      before(:each) { allow(left).to receive(:images).and_return([]) }

      it "should return an empty set" do
        expect(left.intersection right).to be_empty
      end
    end

    context "the intersection is the null set" do
      it "should return an empty set" do
        expect(left.intersection right).to be_empty
      end
    end

    context "the intersection is non-empty" do
      before(:each) do
        allow(left).to receive(:images).and_return([a, b])
      end

      it "should return a set of the intersection" do
        expect(left.intersection right).to contain_exactly(b)
      end
    end
  end
end
