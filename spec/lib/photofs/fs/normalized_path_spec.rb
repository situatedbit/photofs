require 'photofs/fs/normalized_path'

describe PhotoFS::FS::NormalizedPath do
  let(:klass) { PhotoFS::FS::NormalizedPath }

  describe :new do
    context 'root parameter missing' do
      it 'will raise an exception' do
        expect { klass.new({ real: '/test/' }) }.to raise_exception(ArgumentError)
      end
    end

    context 'real parameter missing' do
      it 'will raise an exception' do
        expect { klass.new({ root: '/test' }) }.to raise_exception(ArgumentError)
      end
    end

    context 'real path not under root' do
      it 'will raise an exception' do
        expect { klass.new({ real: '/test', root: '/fail' }) }.to raise_exception(PhotoFS::FS::NormalizedPathException)
      end
    end
  end

  describe :path do
    let(:root_path) { '/a/b' }

    context 'raw path is below root' do
      let(:real_path) { '/a/b/c' }

      it { expect(klass.new({ real: real_path, root: root_path}).path).to eq('c') }

      it { expect(klass.new({ real: real_path, root: root_path}).path).to be_an_instance_of(PhotoFS::FS::RelativePath) }
    end

    context 'raw path is root' do
      let(:real_path) { root_path }

      it { expect(klass.new({ real: real_path, root: root_path}).path).to eq('') }
    end
  end # :path
end
