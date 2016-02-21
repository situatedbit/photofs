require 'photofs/core/image_set'
require 'photofs/core/image'
require 'photofs/core/tag'

describe PhotoFS::Core::ImageSet do
  let(:set) { PhotoFS::Core::ImageSet.new }

  describe :initialize do
    let(:options) do
      { :set => 'set', 
        :filter => 'filter',
        :parent => 'parent'
      }
    end
    let(:set) { PhotoFS::Core::ImageSet.new(options) }

    it 'takes :set option' do
      expect(set.instance_variable_get(:@set)).to eq(options[:set])
    end

    it 'takes :filter option' do
      expect(set.instance_variable_get(:@filter)).to eq(options[:filter])
    end

    it 'takes :parent option' do
      expect(set.instance_variable_get(:@parent)).to eq(options[:parent])
    end
  end

  describe :& do
    let(:tag1) { PhotoFS::Core::Tag.new 'tag1' }
    let(:tag2) { PhotoFS::Core::Tag.new 'tag2' }
    let(:set) { PhotoFS::Core::ImageSet.new }

    context 'when the set is empty' do
      it 'should return an empty set' do
        expect(set.&([tag1]).all).to be_empty
      end
    end

    context 'when parameter is empty' do
      before(:example) do
        set.add(PhotoFS::Core::Image.new 'test')
      end

      it 'should return an empty set' do
        expect(set.&([]).all).to be_empty
      end
    end

    context 'when the intersection is empty' do
      before(:example) do
        set.add(PhotoFS::Core::Image.new 'test')

        tag1.add(PhotoFS::Core::Image.new 'test2')
        tag2.add(PhotoFS::Core::Image.new 'test3')
        tag2.add(PhotoFS::Core::Image.new 'test4')
      end

      it 'should return an empty set' do
        expect(set.& [tag1, tag2]).to be_empty
      end
    end

    context 'when the intersection is not empty' do
      let(:image1) { PhotoFS::Core::Image.new 'test1' }
      let(:image2) { PhotoFS::Core::Image.new 'test2' }
      let(:image3) { PhotoFS::Core::Image.new 'test3' }

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

      it 'should return exclusive set filtered by parameter sets' do
        expect(set.&([tag1, tag2]).all).to contain_exactly(image2, image3)
      end
    end
  end # :&

  describe :add do
    let(:image) { PhotoFS::Core::Image.new 'test' }

    context 'when there is no parent set' do
      before(:example) do
        set.instance_variable_set(:@parent, nil)
      end

      it 'should directly to local set' do
        expect(set.instance_variable_get(:@set)).to receive(:<<).with(image)

        set << image
      end
    end

    context 'when there is a parent set' do
      let(:parent) { PhotoFS::Core::ImageSet.new }
      let(:set) { PhotoFS::Core::ImageSet.new(:parent => parent) }

      it 'should add to the parent root set' do
        expect(set.send :root_set).to receive(:<<).with(image)

        set << image
      end
    end
  end # :add

  describe :find_by_path do
    let(:image_a) { PhotoFS::Core::Image.new 'path-a' }
    let(:image_b) { PhotoFS::Core::Image.new 'path-b' }

    context 'when an image matches the path' do
      before(:example) do
        allow(set).to receive(:range).and_return(Set.new([image_a, image_b]))
      end

      it 'should return that image' do
        expect(set.find_by_path image_a.path).to be image_a
      end
    end

    context 'when no image matches the path' do
      before(:example) do
        allow(set).to receive(:range).and_return(Set.new([image_b]))
      end

      it 'should return nil' do
        expect(set.find_by_path image_a.path).to be nil
      end
    end
  end # :find_by_path

  describe :range do
    let(:set) { PhotoFS::Core::ImageSet.new }

    let(:all) { Proc.new { |i| true } }
    let(:odd) { Proc.new { |i| i % 2 == 1 } }
    let(:mod_five) { Proc.new { |i| i % 5 == 0 } }
    let(:five) { Proc.new { |i| i == 5 } }

    it 'should be a set' do
      expect(set.range.is_a? Set).to be true
    end

    context 'when there is no parent set' do
      let(:local_set) { Set.new [1, 2, 3, 4, 5] }
      let(:set) { PhotoFS::Core::ImageSet.new({:set => local_set, :filter => odd})}

      it 'should filter the local set' do
        expect(set.range.to_a).to contain_exactly(*[1, 3, 5])
      end
    end

    context 'when there is a parent set' do
      let(:parent_set) { Set.new [1, 2, 3, 4, 5] }
      let(:parent) { PhotoFS::Core::ImageSet.new(:set => parent_set) }
      let(:set) { PhotoFS::Core::ImageSet.new({:parent => parent, :filter => mod_five})}

      it 'should filter the parent set' do
        expect(set.range.to_a).to contain_exactly(5)
      end
    end

    context 'when three sets are chained together' do
      let(:grandparent_set) { Set.new((0..29).to_a) }
      let(:grandparent) { PhotoFS::Core::ImageSet.new({:set => grandparent_set, :filter => odd}) }
      let(:parent) { PhotoFS::Core::ImageSet.new({:parent => grandparent, :filter => mod_five}) }
      let(:set) { PhotoFS::Core::ImageSet.new({:parent => parent, :filter => five}) }

      it 'should filter the base set twice' do
        expect(parent.range.to_a).to contain_exactly(5, 15, 25)
      end

      it 'should filter down the parent set sequentially' do
        expect(set.range.to_a).to contain_exactly(5)
      end
    end
  end # :range

  describe :filter do
    let(:parent) { PhotoFS::Core::ImageSet.new }

    it 'be a new set with parent as self' do    
      expect(parent.filter { |i| true }.instance_variable_get(:@parent)).to equal(parent)
    end
  end # :filter
end
