require 'spec_helper'
require 'image'

describe PhotoFS::Image do
  let(:path) { 'kawaguchiko' }

  describe "#hash" do
    let(:left) { PhotoFS::Image.new path }
    let(:right) { PhotoFS::Image.new(path * 2) }

    it "should return a fixnum" do
      expect(left.hash.is_a? Fixnum).to be true
    end

    it "should be the same for images with the same path" do
      expect(left.hash).to eq(PhotoFS::Image.new(path).hash)
    end

    it "should be different for images with different paths" do
      expect(left.hash).not_to eq(right.hash)
    end
  end

  describe "== method" do
    let(:left) { PhotoFS::Image.new(path) }

    context "other is not an image" do
      let(:right) { 'an other' }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other does not have the same path" do
      let(:right) { PhotoFS::Image.new(left.path * 2) }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other is an image with same path" do
      let(:right) { PhotoFS::Image.new('') }

      before(:each) do
        allow(right).to receive(:path).and_return(left.path)
      end

      it "should be true" do
        expect(left == right). to be true
      end
    end
  end
end
