require 'photofs/fs/normalized_path'

describe PhotoFS::FS::NormalizedPath do
  before(:each) do
    allow(PhotoFS::FS).to receive(:images_path).and_return('/a/b')
  end

  let(:klass) { PhotoFS::FS::NormalizedPath }

  describe :root do
    it { expect(klass.new('whatever/path').root).to eq('/a/b') }

    it { expect(klass.new('a/b', {:root => '/my/root'}).root).to eq('/my/root') }
  end

  describe :path do
    let(:fs) { double('FileSystem') }
    let(:images_path) { '/a/b' }

    before(:each) do
      allow(fs).to receive(:realpath).and_return(realpath)
      allow(fs).to receive(:images_path).and_return(images_path)
    end

    context 'raw path is below root' do
      let(:realpath) { '/a/b/c' }

      it { expect(klass.new('1/2/3', {:file_system => fs}).path).to eq('c') }

      it { expect(klass.new('1/2/3', {:file_system => fs}).path).to be_an_instance_of(PhotoFS::FS::RelativePath) }
    end

    context 'raw path is root' do
      let(:realpath) { '/a/b' }

      it { expect(klass.new('/a/b', {:file_system => fs}).path).to eq('') }
    end

    context 'raw path is above root' do
      let(:realpath) { '/a' }

      it 'should raise exception' do
        expect { klass.new('/a', {:file_system => fs}).path }.to raise_exception(PhotoFS::FS::NormalizedPathException)
      end
    end

    context 'raw path does not overlap root' do
      let(:realpath) { '/c' }

      it 'should raise exception' do
        expect { klass.new('/c', {:file_system => fs}).path }.to raise_exception(PhotoFS::FS::NormalizedPathException)
      end
    end

    context 'raw path is not a valid path' do
      let(:realpath) { '/ignored-path' }

      before(:each) do
        allow(fs).to receive(:realpath).and_raise(Exception)
      end

      it 'should raise exception' do
        expect { klass.new('/bad/path', {:file_system => fs}).path }.to raise_exception(PhotoFS::FS::NormalizedPathException)
      end
    end

    context 'root was never set systemwide' do
      let(:realpath) { '/ignored-path' }

      before(:each) do
        allow(fs).to receive(:images_path).and_return(nil)
      end

      it 'should raise exception' do
        expect { klass.new('/a').path }.to raise_exception(PhotoFS::FS::NormalizedPathException)
      end
    end
  end # :path
end
