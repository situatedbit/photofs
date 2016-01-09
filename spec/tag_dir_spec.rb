require 'spec_helper'
require 'tag_dir'
require 'tag_set'

describe PhotoFS::TagDir do
  describe '#add' do
    it 'should be implemented'
  end

  describe '#stat' do
    let(:tag_dir) { PhotoFS::TagDir.new('nihonbashi', PhotoFS::TagSet.new) }
    let(:size) { 687 }

    before(:example) do
      allow(tag_dir).to receive(:size).and_return(size)
    end

    it 'should return writable by owner' do
      expect(tag_dir.stat.mode & PhotoFS::Stat::MODE_MASK & PhotoFS::Stat::PERM_USER_WRITE).to be PhotoFS::Stat::PERM_USER_WRITE
    end

    it 'should include size' do
      expect(tag_dir.stat.size).to be size
    end
  end

  describe '#node_hash' do
    let(:tag_dir) { PhotoFS::TagDir.new('nihonbashi', PhotoFS::TagSet.new) }

    context 'when there are no files or dirs' do
      before(:example) do
        allow(tag_dir).to receive(:files).and_return([])
        allow(tag_dir).to receive(:dirs).and_return([])
      end

      it 'should return an empty hash' do
        expect(tag_dir.send :node_hash).to eq({})
      end
    end

    context 'when there are files and dirs' do
      let(:node_class) { Struct.new(:name) }
      let(:files) { [node_class.new('first'), node_class.new('second')] }
      let(:dirs) { [node_class.new('third'), node_class.new('fourth')] }

      let(:node_hash) do
        { files[0].name => files[0],
          files[1].name => files[1],
          dirs[0].name => dirs[0],
          dirs[1].name => dirs[1] }
      end

      before(:example) do
        allow(tag_dir).to receive(:files).and_return(files)
        allow(tag_dir).to receive(:dirs).and_return(dirs)
      end

      it 'should return a hash of their names as keys and selves as values' do
        expect(tag_dir.send :node_hash).to eq(node_hash)
      end
    end
  end

  describe '#dirs' do
    let(:tag_dir) { PhotoFS::TagDir.new('nihonbashi', PhotoFS::TagSet.new) }

    context 'there are no dir_tags' do
      before(:example) do
        allow(tag_dir).to receive(:dir_tags).and_return([])
      end

      it 'should return an empty collection' do
        expect(tag_dir.send :dirs).to be_empty
      end
    end

    context 'there is a dir_tag' do
      let(:tag_class) { Struct.new(:name) }
      let(:dir_tags) { [tag_class.new('c'), tag_class.new('d')] }
      let(:query_tag_names) { ['a', 'b'] }
      let(:tags) { PhotoFS::TagSet.new }

      before(:example) do
        tag_dir.instance_variable_set(:@tags, tags)
        tag_dir.instance_variable_set(:@query_tag_names, query_tag_names)

        allow(tag_dir).to receive(:dir_tags).and_return(dir_tags)
      end

      it 'should return a new collection with a tag_dir with combined query tags' do
        expect(PhotoFS::TagDir).to receive(:new).with('c', tags, ['a', 'b', 'c'])
        expect(PhotoFS::TagDir).to receive(:new).with('d', tags, ['a', 'b', 'd'])

        tag_dir.send :dirs
      end
    end
  end

  describe '#size' do
    let(:tag_dir) { PhotoFS::TagDir.new('nihonbashi', PhotoFS::TagSet.new) }
    let(:file_name) { 'ぎんざ' }
    let(:dir_name) { 'おだいば' }

    context 'when the directory is empty' do
      before(:example) do
        allow(tag_dir).to receive(:node_hash).and_return({})
      end

      it 'should return 0' do
        expect(tag_dir.send :size).to be 0
      end
    end

    context 'when there are directory contents' do
      let(:size) { (file_name + dir_name).length }

      let(:node_hash) do
        { file_name => PhotoFS::Node.new(file_name),
          dir_name => PhotoFS::Node.new(dir_name) }
      end

      before(:example) do
        allow(tag_dir).to receive(:node_hash).and_return(node_hash)
      end

      it 'should return the sum of the node names' do
        expect(tag_dir.send :size).to be(size)
      end
    end
  end

end
