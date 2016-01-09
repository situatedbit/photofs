require 'spec_helper'
require 'image_set'
require 'image'
require 'tag'

describe PhotoFS::ImageSet do
  let(:set) { PhotoFS::ImageSet.new }

  describe '#initialize' do
    let(:other_set) { PhotoFS::ImageSet.new }

    context 'when passed another collection' do
      before(:example) do
        other_set.add(PhotoFS::Image.new 'test')
      end

      it 'adopts the collection set as its own' do
        expect(PhotoFS::ImageSet.new(other_set).images).to contain_exactly(*other_set.images)
      end
    end
  end

  describe '#add' do
    let(:image) { PhotoFS::Image.new 'test' }

    before(:example) do
      2.times { set.add image }
    end

    it 'should replace duplicates' do
      expect(set.all.length).to be 1
    end
  end

  describe '#&' do
    let(:tag1) { PhotoFS::Tag.new 'tag1' }
    let(:tag2) { PhotoFS::Tag.new 'tag2' }

    context 'when the set is empty' do
      before(:example) { set.instance_variable_set(:@images_hash, {})  }

      it 'should return an empty set' do
        expect(set.&([tag1]).all).to be_empty
      end
    end

    context 'when tags parameter is empty' do
      before(:example) { set.add(PhotoFS::Image.new 'test') }

      it 'should return an empty set' do
        expect(set.&([]).all).to be_empty
      end
    end

    context 'when the tags do not include any images in the set' do
      before(:example) do
        set.add(PhotoFS::Image.new 'test')

        tag1.add(PhotoFS::Image.new 'test2')
        tag2.add(PhotoFS::Image.new 'test3')
        tag2.add(PhotoFS::Image.new 'test4')
      end

      it 'should return an empty set' do
        expect(set.& [tag1, tag2]).to be_empty
      end
    end

    context 'when the tags include images in the set' do
      let(:image1) { PhotoFS::Image.new 'test1' }
      let(:image2) { PhotoFS::Image.new 'test2' }
      let(:image3) { PhotoFS::Image.new 'test3' }

      before(:example) do
        set.add(image1)
        set.add(image2)
        set.add(image3)

        tag1.add(image2)
        tag1.add(image3)

        tag2.add(image1)
        tag2.add(image2)
        tag2.add(image3)
      end

      it 'should return exclusive set filtered by tags' do
        expect(set.&([tag1, tag2]).all).to contain_exactly(image2, image3)
      end
    end
  end

end
