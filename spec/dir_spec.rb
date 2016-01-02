require 'spec_helper'
require 'dir'

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

    it 'should not have any nodes' do
      expect(dir.nodes).to be_empty
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

  describe "add method" do
    let(:node) { PhotoFS::Node.new('test', nil) }

    it 'should set the parent on the node' do
      expect(node).to receive(:parent=).with(dir)

      dir.add(node)
    end
  end

  describe 'search method' do
    context 'when path is empty' do
      it 'should return itself' do
        expect(dir.search('')).to eq(dir)
      end
    end

    context 'when the matching node is a directory' do
      let(:search_path) { ['ikebukuro', 'shinjuku'] }
      let(:found_node_name) { search_path.first }
      let(:truncated_search_path) { ['shinjuku'] }
      let(:found_node) { PhotoFS::Dir.new(found_node_name, dir) }

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
      let(:file) { PhotoFS::Dir.new(file_name, dir) }

      before(:each) do
        allow(dir).to receive(:node_hash).and_return( { file_name => file } )
      end

      it 'should return that node' do      
        expect(dir.search([file_name])).to eq(file)
      end
    end

    context 'when there is no match' do
      it 'should return nil' do
        expect(dir.search(['garbage'])).to be nil
      end
    end
  end
end
