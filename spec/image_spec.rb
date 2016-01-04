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
end
