require 'rfuse'
require 'photofs/fuse'

describe PhotoFS::Fuse::Fuse do
  let(:context) { instance_double('RFuse::Context') }
  let(:root_dir) { instance_double('PhotoFS::RootDir') }
  let(:fuse) { PhotoFS::Fuse::Fuse.new({:source => 'source-path', :mountpoint => 'mount-point'}) }

  before(:example) do
    allow(PhotoFS::Fuse::RootDir).to receive(:new).and_return(root_dir)

    allow(fuse).to receive(:log) # swallow log messages
  end

  describe :rename do
    let(:from) { '/a/b/c/from' }
    let(:to) { '/1/2/3/to' }
    let(:from_path) { PhotoFS::Fuse::RelativePath.new from }
    let(:to_path) { PhotoFS::Fuse::RelativePath.new to }
    let(:from_parent_node) { instance_double('PhotoFS::Fuse::Dir', :rename => nil) }
    let(:to_parent_node) { instance_double('PhotoFS::Fuse::Dir') }

    context 'when from does not exist' do
      before(:example) do
        allow(fuse).to receive(:search).with(from_path.parent).and_raise(Errno::ENOENT)
        allow(fuse).to receive(:search).with(to_path.parent).and_return(to_parent_node)
      end

      it 'should not be permitted' do
        expect { fuse.rename(context, from, to) }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when to parent does not exist' do
      before(:example) do
        allow(fuse).to receive(:search).with(from_path.parent).and_return(from_parent_node)
        allow(fuse).to receive(:search).with(to_path.parent).and_raise(Errno::ENOENT)
      end

      it 'should not be permitted' do
        expect { fuse.rename(context, from, to) }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when from and to paths are valid' do
      let(:from_name) { from_path.name }
      let(:to_name) { to_path.name }

      before(:example) do
        allow(fuse).to receive(:search).with(from_path.parent).and_return(from_parent_node)
        allow(fuse).to receive(:search).with(to_path.parent).and_return(to_parent_node)
      end

      it 'should send :rename to from parent node' do
        expect(from_parent_node).to receive(:rename).with(from_name, to_parent_node, to_name)

        fuse.rename(context, from, to)
      end

      it 'should save the data store' do
        expect(fuse).to receive(:save!)

        fuse.rename(context, from, to)
      end
    end
  end

  describe :readdir do
    let(:filler) { instance_double("filler") }
    let(:dir) { double('search-dir') }

    before(:example) do
      allow(fuse).to receive(:search).and_return(dir)
    end

    context 'when path is not for a directory' do
      before(:each) do
        allow(dir).to receive(:directory?).and_return(false)
      end

      it 'will throw an error' do
        expect { fuse.readdir(context, 'path', filler, 0, 0) }.to raise_error(Errno::ENOTDIR)
      end
    end

    context 'when path is a directory' do
      let(:node1) { instance_double('PhotoFS::Fuse::Node', :stat => 'stat1') }
      let(:node2) { instance_double('PhotoFS::Fuse::Node', :stat => 'stat2') }
      let(:nodes) do
        { 'name-1' => node1, 'name-2' => node2 }
      end

      before(:example) do
        allow(dir).to receive(:directory?).and_return(true)
        allow(dir).to receive(:nodes).and_return(nodes)
      end

      it 'will call filler with names from lookup table' do
        expect(filler).to receive(:push).with('name-1', node1.stat, 0)
        expect(filler).to receive(:push).with('name-2', node2.stat, 0)

        fuse.readdir(context, 'path', filler, 0, 0)
      end

    end
  end # :readdir

  describe :unlink do
    context 'when the file does not exist' do
      before(:example) do
        allow(fuse).to receive(:search).and_raise(Errno::ENOENT)
      end

      it 'should raise ENOENT' do
        expect { fuse.unlink(context, '/some-file') }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when the file does exist' do
      let(:parent_node) { instance_double('PhotoFS::Fuse::Dir', :remove => nil) }
      let(:parent_path) { PhotoFS::Fuse::RelativePath.new('/t/good') }

      before(:example) do
        allow(fuse).to receive(:search).with(parent_path).and_return(parent_node)
      end

      it 'should call remove on parent node' do
        expect(parent_node).to receive(:remove).with('file')

        fuse.unlink(context, '/t/good/file')
      end

      it 'should save the data store' do
        expect(fuse).to receive(:save!)

        fuse.unlink(context, '/t/good/file')
      end
    end
  end # :unlink
end
