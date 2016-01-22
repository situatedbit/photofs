require 'spec_helper'
require 'dir'
require 'relative_path'
require 'stat'

describe PhotoFS::Dir do
  let(:name) { 'iidabashi' }
  let(:dir) { PhotoFS::Dir.new name }

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
        expect(dir.stat.mode & PhotoFS::Stat::MODE_MASK).to eq(PhotoFS::Stat::MODE_READ_ONLY)
      end

      it "should return real directory" do
        expect(dir.stat.mode & RFuse::Stat::S_IFMT).to eq(RFuse::Stat::S_IFDIR)
      end
    end
  end # top level instance

  describe :add do
    it 'should refuse with not permitted' do
      expect{ dir.add('child-name', PhotoFS::Node.new('blah')) }.to raise_error(Errno::EPERM)
    end
  end

  describe :mkdir do
    it 'should not be implemented' do
      expect{ dir.mkdir 'anything' }.to raise_error(NotImplementedError)
    end
  end

  describe :rename do
    it 'should not be implemented' do
      expect{ dir.rename 'child-name', PhotoFS::Node.new('to-parent'), 'to-name' }.to raise_error(Errno::EPERM)
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
        expect(dir.search(PhotoFS::RelativePath.new('./'))).to eq(dir)
      end
    end

    context 'when the matching node is a directory' do
      let(:search_path) { PhotoFS::RelativePath.new('ikebukuro/shinjuku') }
      let(:found_node_name) { search_path.top_name }
      let(:truncated_search_path) { PhotoFS::RelativePath.new('./shinjuku') }
      let(:found_node) { PhotoFS::Dir.new(found_node_name, {:parent => dir}) }

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
      let(:file) { PhotoFS::Dir.new(file_name, {:parent => dir}) }

      before(:each) do
        allow(dir).to receive(:node_hash).and_return( { file_name => file } )
      end

      it 'should return that node' do      
        expect(dir.search(PhotoFS::RelativePath.new(file_name))).to eq(file)
      end
    end

    context 'when there is no match' do
      before(:each) do
        allow(dir).to receive(:node_hash).and_return( {} )
      end

      it 'should return nil' do
        expect(dir.search(PhotoFS::RelativePath.new('garbage'))).to be nil
      end
    end
  end
end
