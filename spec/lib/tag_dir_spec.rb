require 'spec_helper'
require 'tag_dir'
require 'tag_set'
require 'stat'

describe PhotoFS::TagDir do
  describe :new do
    let(:parent) { PhotoFS::Dir.new 'お母さん' }
    let(:query_tag_names) { ['query', 'tag', 'names'] }
    let(:default_options) { {:query_tag_names => ['deafult', 'tag', 'names']} }

    it 'should take an optional parent' do
      dir = PhotoFS::TagDir.new('name', {}, {:parent => parent})

      expect(dir.instance_variable_get(:@parent)).to be parent
    end

    it 'should take optional query_tag_names' do
      dir = PhotoFS::TagDir.new('name', {}, {:query_tag_names => query_tag_names})

      expect(dir.instance_variable_get(:@query_tag_names)).to be query_tag_names
    end

    it 'should merge options with defaults' do
      options = {:special => 'option'}

      allow_any_instance_of(PhotoFS::TagDir).to receive(:default_options).and_return(default_options)

      dir = PhotoFS::TagDir.new 'name', {}, options

      expect(dir.instance_variable_get(:@query_tag_names)).to eq(default_options[:query_tag_names])
      expect(dir.instance_variable_get(:@options)[:special]).to eq(options[:special])
    end
  end

  describe :mkdir do
    let(:tags) { PhotoFS::TagSet.new }
    let(:dir) { PhotoFS::TagDir.new('t', tags) }
    let(:tag_name) { 'おさか' }
    let(:tag) { PhotoFS::Tag.new tag_name }

    context 'when dir is the top-most tag directory' do
      before(:example) do
        allow(dir).to receive(:is_tags_root?).and_return(true)
      end

      context 'when the tag does not exist' do
        before(:example) do
          allow(dir).to receive(:dir_tags).and_return([])
        end

        it 'should create a new tag' do
          expect(tags).to receive(:add?).with(tag)

          dir.mkdir(tag_name)
        end
      end

      context 'when the tag exists' do
        let(:dir_tags) { [tag] }

        before(:example) do
          allow(dir).to receive(:dir_tags).and_return(dir_tags)
        end

        it 'should throw an error' do
          expect { dir.mkdir tag_name }.to raise_error(Errno::EEXIST)
        end
      end
    end

    context 'when the dir is not the top-most tag directory' do
      before(:example) do
        allow(dir).to receive(:is_tags_root?).and_return(false)
      end

      it 'should throw an error' do
        expect { dir.mkdir tag_name }.to raise_error(Errno::EPERM)
      end
    end
  end

  describe :rmdir do
    let(:tags) { PhotoFS::TagSet.new }
    let(:dir) { PhotoFS::TagDir.new('t', tags) }
    let(:dir_tags) { [] }
    let(:tag_name) { 'ほっかいど' }
    let(:tag) { PhotoFS::Tag.new tag_name }

    context 'when the tag does not exist' do
      before(:example) do
        allow(dir).to receive(:dir_tags).and_return(dir_tags)
        allow(dir_tags).to receive(:include?).with(tag).and_return(false)
      end

      it 'should throw an error' do
        expect { dir.rmdir tag_name }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when the tag does exist' do
      before(:example) do
        allow(dir.instance_variable_get(:@tags)).to receive(:find_by_name).with(tag_name).and_return(tag)
        allow(dir).to receive(:dir_tags).and_return(dir_tags)
        allow(dir_tags).to receive(:include?).with(tag).and_return(true)
      end

      context 'when the tag is at the top level' do
        before(:example) do
          allow(dir).to receive(:is_tags_root?).and_return(true)
        end

        it 'should remove the tag from the tag set' do
          expect(tags).to receive(:delete).with(tag)

          dir.rmdir tag_name
        end
      end

      context 'when the tag is not at the top level' do
        let(:images) { PhotoFS::ImageSet.new }

        before(:example) do
          allow(dir).to receive(:is_tags_root?).and_return(false)
          allow(dir).to receive(:images).and_return(images)
        end

        it 'should remove that tag from any images that are in the current directory' do
          expect(tag).to receive(:subtract).with(images)

          dir.rmdir tag_name
        end
      end
    end # rmdir

  end

  describe :stat do
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

  describe :node_hash do
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

  describe :dirs do
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
        expect(PhotoFS::TagDir).to receive(:new).with('c', tags, {:query_tag_names => ['a', 'b', 'c'], :parent => tag_dir})
        expect(PhotoFS::TagDir).to receive(:new).with('d', tags, {:query_tag_names => ['a', 'b', 'd'], :parent => tag_dir})

        tag_dir.send :dirs
      end
    end
  end

  describe :size do
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
