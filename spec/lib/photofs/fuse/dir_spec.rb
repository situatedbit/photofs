require 'photofs/fs/relative_path'
require 'photofs/fuse/dir'
require 'photofs/fuse/stat'

describe PhotoFS::Fuse::Dir do
  let(:name) { 'iidabashi' }
  let(:dir) { PhotoFS::Fuse::Dir.new name }

  describe 'top-level instance' do
    it 'should have a name' do
      expect(dir.name).to eq(name)
    end

    it 'should not have a parent' do
      expect(dir.parent).to be nil
    end

    it 'should be a directory' do
      expect(dir.directory?).to be true
    end

    describe 'stat method' do
      it "should return read-only" do
        expect(dir.stat.mode & PhotoFS::Fuse::Stat::MODE_MASK).to eq(PhotoFS::Fuse::Stat::MODE_READ_ONLY)
      end

      it "should return real directory" do
        expect(dir.stat.mode & RFuse::Stat::S_IFMT).to eq(RFuse::Stat::S_IFDIR)
      end
    end
  end # top level instance

  describe :add do
    it 'should refuse with not permitted' do
      expect{ dir.add('child-name', PhotoFS::Fuse::Node.new('blah')) }.to raise_error(Errno::EPERM)
    end
  end

  describe :mkdir do
    it 'should not be implemented' do
      expect{ dir.mkdir 'anything' }.to raise_error(NotImplementedError)
    end
  end

  describe :rename do
    it 'should not be implemented' do
      expect{ dir.rename 'child-name', PhotoFS::Fuse::Node.new('to-parent'), 'to-name' }.to raise_error(Errno::EPERM)
    end
  end

  describe :remove do
    it 'should not be permitted' do
      expect{ dir.remove 'child-name' }.to raise_error(Errno::EPERM)
    end
  end

  describe :rmdir do
    it 'should not be implemented' do
      expect{ dir.rmdir 'anything' }.to raise_error(NotImplementedError)
    end
  end

  describe :search do
    context 'when path is empty' do
      it 'should return itself' do
        expect(dir.search(PhotoFS::FS::RelativePath.new('./'))).to eq(dir)
      end
    end

    context 'when the matching node is a directory' do
      let(:search_path) { PhotoFS::FS::RelativePath.new('ikebukuro/shinjuku') }
      let(:found_node_name) { search_path.top_name }
      let(:truncated_search_path) { PhotoFS::FS::RelativePath.new('./shinjuku') }
      let(:found_node) { PhotoFS::Fuse::Dir.new(found_node_name, {:parent => dir}) }

      before(:each) do
        allow(dir).to receive(:node_hash).and_return( { found_node_name => found_node } )
      end

      it 'should call search on that directory with a truncated path' do
        expect(found_node).to receive(:search).with(truncated_search_path)
        dir.search(search_path)
      end
    end

    context 'when the matching node is a file' do
      let(:file_name) { 'ikebukuro' }
      let(:file) { PhotoFS::Fuse::Dir.new(file_name, {:parent => dir}) }

      before(:each) do
        allow(dir).to receive(:node_hash).and_return( { file_name => file } )
      end

      it 'should return that node' do      
        expect(dir.search(PhotoFS::FS::RelativePath.new(file_name))).to eq(file)
      end
    end

    context 'when there is no match' do
      before(:each) do
        allow(dir).to receive(:node_hash).and_return( {} )
      end

      it 'should return nil' do
        expect(dir.search(PhotoFS::FS::RelativePath.new('garbage'))).to be nil
      end
    end
  end # :search

  describe :soft_move do
    it 'should not be implemented' do
      expect { dir.soft_move 'node', 'name' }.to raise_error(Errno::EPERM)
    end
  end

  describe :symlink do
    let(:image) { instance_double('PhotoFS::Core::Image') }

    it 'should raise permission error' do
      expect { dir.symlink image, 'name' }.to raise_error(Errno::EPERM)
    end
  end
end
