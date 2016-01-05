require 'spec_helper'
require 'tag'
require 'image'

describe PhotoFS::Tag do
  let(:name) { 'kawaguchiko' }

  it "should include a name" do
    expect(PhotoFS::Tag.new(name).name).to eq(name)
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
