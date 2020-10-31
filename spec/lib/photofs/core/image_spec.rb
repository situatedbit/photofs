require 'photofs/core/image'

describe PhotoFS::Core::Image do
  let(:path) { 'kawaguchiko' }

  describe :hash do
    let(:left) { PhotoFS::Core::Image.new path }
    let(:right) { PhotoFS::Core::Image.new(path * 2) }

    it "should return a fixnum" do
      expect(left.hash.is_a? Fixnum).to be true
    end

    it "should be the same for images with the same path" do
      expect(left.hash).to eq(PhotoFS::Core::Image.new(path).hash)
    end

    it "should be different for images with different paths" do
      expect(left.hash).not_to eq(right.hash)
    end
  end

  describe :== do
    let(:left) { PhotoFS::Core::Image.new(path) }

    context "other is not an image" do
      let(:right) { 'an other' }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other does not have the same path" do
      let(:right) { PhotoFS::Core::Image.new(left.path * 2) }

      it "should be false" do
        expect(left == right).to be false
      end
    end

    context "other is an image with same path" do
      let(:right) { PhotoFS::Core::Image.new('') }

      before(:each) do
        allow(right).to receive(:path).and_return(left.path)
      end

      it "should be true" do
        expect(left == right). to be true
      end
    end
  end

  describe :name do
    let(:image) { PhotoFS::Core::Image.new('') }

    it 'should replace all forward slashes with dashes and strip leading dashes' do
      allow(image).to receive(:path).and_return('/some/path/to/whatever')

      expect(image.name).to eq('some-path-to-whatever')
    end
  end # :name

  describe :sidecar? do
    let(:image) { PhotoFS::Core::Image }
    let(:irregular_name) { image.new('a/b/1.jpg') }
    let(:normalized_name) { image.new('a/b/2019-12-12-035.jpg') }

    it { expect(irregular_name.sidecar? image.new('a/b/1.jpg')).to be false }
    it { expect(irregular_name.sidecar? image.new('a/b/1.JPG')).to be true }
    it { expect(irregular_name.sidecar? image.new('a/b/1.c2r')).to be true }
    it { expect(irregular_name.sidecar? image.new('a/1.c2r')).to be false }
    it { expect(irregular_name.sidecar? image.new('1.c2r')).to be false }
    it { expect(irregular_name.sidecar? image.new('a/b/1')).to be true }

    # additional extensions are ignored for irregular names
    it { expect(irregular_name.sidecar? image.new('a/b/1.whatever')).to be true }
    it { expect(irregular_name.sidecar? image.new('a/b/1.whatever.nevermind')).to be true }

    # hyphen-delineated notes are honored for regular and irregular names
    it { expect(irregular_name.sidecar? image.new('a/b/1-small.xcf.jpg')).to be true }
    it { expect(irregular_name.sidecar? image.new('a/b/1-p123-1200dpi.tif')).to be true }

    it { expect(normalized_name.sidecar? image.new('a/b/2019-12-12-035-small.jpg')).to be true }
    it { expect(normalized_name.sidecar? image.new('a/b/2019-12-12-035-8x10-1200dpi.xcf.jpg')).to be true }
  end
end
