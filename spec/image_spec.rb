require 'spec_helper'
require 'image'

describe PhotoFS::Image do
  let(:path) { 'kawaguchiko' }

  describe "id method" do
    let(:left) { PhotoFS::Image.new(path) }
    let(:right) { PhotoFS::Image.new(path * 2) }

    it "should return a string" do
      expect(left.id.is_a? String).to be true
    end

    it "should be the same for images with the same path" do
      expect(left.id).to eq(PhotoFS::Image.new(path).id)
    end

    it "should be different for images with different paths" do
      expect(left.id).not_to eq(right.id)
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

    context "other does not have the same id" do
      let(:right) { PhotoFS::Image.new(left.id * 2) }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other is an image with same id" do
      let(:right) { PhotoFS::Image.new('') }

      before(:each) do
        allow(right).to receive(:id).and_return(left.id)
      end

      it "should be true" do
        expect(left == right). to be true
      end
    end
  end
end
