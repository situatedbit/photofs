require 'photofs/core/image_set'
require 'photofs/core/image'
require 'photofs/core/tag'

describe PhotoFS::Core::ImageSet do
  let(:set) { PhotoFS::Core::ImageSet.new }

  describe :initialize do
    let(:options) do
      { :set => 'set' }
    end
    let(:set) { PhotoFS::Core::ImageSet.new(options) }

    it 'takes :set option' do
      expect(set.instance_variable_get(:@set)).to eq(options[:set])
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

     it 'should directly to local set' do
      expect(set.instance_variable_get(:@set)).to receive(:<<).with(image)

      set << image
    end
  end # :add

  describe :find_by_path do
    let(:image_a) { PhotoFS::Core::Image.new 'path-a' }
    let(:image_b) { PhotoFS::Core::Image.new 'path-b' }

    context 'when an image matches the path' do
      before(:example) do
        allow(set).to receive(:set).and_return(Set.new([image_a, image_b]))
      end

      it 'should return that image' do
        expect(set.find_by_path image_a.path).to be image_a
      end
    end

    context 'when no image matches the path' do
      before(:example) do
        allow(set).to receive(:set).and_return(Set.new([image_b]))
      end

      it 'should return nil' do
        expect(set.find_by_path image_a.path).to be nil
      end
    end
  end # :find_by_path

  describe :sidecars do
    context 'when image set is empty' do
      let(:images) { Set.new([double(PhotoFS::Core::Image)]) }

      it { expect(set.sidecars images).to be_empty }
    end

    context 'when images parameter set is empty' do
      let(:images) { Set.new }

      before(:example) do
        set.add double(PhotoFS::Core::Image)
      end

      it { expect(set.sidecars images).to be_empty }
    end

    context 'when there are images with sidecars' do
      let(:i1) { double(PhotoFS::Core::Image, :sidecar? => false) }
      let(:i2) { double(PhotoFS::Core::Image, :sidecar? => false) }
      let(:sidecar1) { double(PhotoFS::Core::Image, :sidecar? => false) }
      let(:sidecar2) { double(PhotoFS::Core::Image, :sidecar? => false) }

      before(:example) do
        allow(i1).to receive(:sidecar?).with(sidecar1).and_return(true)
        allow(i2).to receive(:sidecar?).with(sidecar2).and_return(true)

        [i1, i2, sidecar1, sidecar2].each { |i| set.add i }
      end

      context 'when set contains sidecar images of images' do
        let(:images) { Set.new([i1, i2]) }

        it 'should contain those new sidecar images' do
          expect(set.sidecars images).to contain_exactly(sidecar1, sidecar2)
        end
      end

      context 'when an image and its sidecar image are both in the images parameter set' do
        let(:images) { Set.new([i1, i2, sidecar1]) }

        it 'should not contain that sidecar image' do
          expect(set.sidecars images).to contain_exactly(sidecar2)
        end
      end
    end
  end # :sidecars
end
