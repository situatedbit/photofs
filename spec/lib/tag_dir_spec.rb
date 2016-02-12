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

  describe :add do
    let(:query_tag_names) { ['tag1', 'tag2'] }
    let(:payload) { 'the image' }
    let(:node) { instance_double('PhotoFS::Node', :name => '子供', :path => 'garbage', :payload => payload) }
    let(:dir) { PhotoFS::TagDir.new 'じしょ' , {}, {:query_tag_names => query_tag_names}}
    let(:images_domain) { instance_double('PhotoFS::ImageSet') }

    before(:example) do
      dir.instance_variable_set(:@images_domain, images_domain)

      allow(dir).to receive(:images).and_return(instance_double('images', {:include? => false}))
    end

    context 'when node payload is already in images set' do
      before(:example) do
        allow(dir).to receive(:images).and_return(instance_double('images', {:include? => true}))
      end

      it 'should not be permitted' do
        expect { dir.add('child', node) }.to raise_error(Errno::EEXIST)
      end
    end

    context 'when dir is tag root' do
      before(:example) do
        allow(dir).to receive(:is_tags_root?).and_return(true)
      end

      it 'should not be permitted' do
        expect { dir.add('child', node) }.to raise_error(Errno::EPERM)
      end
    end

    context 'when node image is not in the image domain' do
      before(:example) do
        allow(images_domain).to receive(:include?).and_return(false)
      end

      it 'should not be permitted' do
        expect { dir.add('child', node) }.to raise_error(Errno::EPERM)
      end
    end

    context 'when node is image in image domain' do
      let(:tag_a) { instance_double('PhotoFS::Tag') }
      let(:tag_b) { instance_double('PhotoFS::Tag') }

      before(:example) do
        allow(images_domain).to receive(:include?).and_return(true)
        allow(dir).to receive(:query_tags).and_return([tag_a, tag_b])
      end

      it 'should tag image with all query tag names' do
        expect(tag_a).to receive(:add).with(node.payload)
        expect(tag_b).to receive(:add).with(node.payload)

        dir.add('some-name', node)
      end
    end
  end # :add

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
  end # :mkdir

  describe :rename do
    it 'it should be implemented'
  end

  describe :remove do
    let(:dir) { PhotoFS::TagDir.new 'じしょ' , {}, {:query_tag_names => []}}

    context 'when the child does not exist in files' do
      let(:node_hash) { Hash.new }

      before(:example) do
        allow(dir).to receive(:node_hash).and_return(node_hash)
      end

      it 'should raise ENOENT' do
        expect { dir.remove('whatever') }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when the child exists and' do
      let(:child_name) { 'the-image' }
      let(:tag_a) { instance_double('PhotoFS::Tag', :name => 'good') }
      let(:image) { instance_double('PhotoFS::Image') }
      let(:child_node) { instance_double('PhotoFS::File', :name => child_name, :payload => image, :directory? => false) }
      let(:node_hash) { {child_node.name => child_node} }

      before(:example) do
        allow(dir).to receive(:query_tags).and_return(query_tags)
        allow(dir).to receive(:node_hash).and_return(node_hash)
      end

      context 'the tag one level deep' do
        let(:query_tags) { [tag_a] }

        it 'should untag image' do
          expect(tag_a).to receive(:remove).with(image)

          dir.remove(child_name)
        end
      end

      context 'when tag is nested' do
        let(:tag_b) { instance_double('PhotoFS::Tag', :name => 'bad') }
        let(:query_tags) { [tag_a, tag_b] }

        it 'should untag image with each tag in nesting' do
          expect(tag_a).to receive(:remove).with(image)
          expect(tag_b).to receive(:remove).with(image)

          dir.remove(child_name)
        end
      end
    end
  end # :remove

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

        it 'should remove that tag from any images that are in the current directory with a destructive method call'
      end
    end # rmdir
  end

  describe :soft_move do
    let(:tag_set) { PhotoFS::TagSet.new }
    let(:tag_dir) { PhotoFS::TagDir.new('日本橋', tag_set) }
    let(:name) { 'new name' }
    let(:node) { instance_double('PhotoFS::File', :payload => 'node-payload', :directory? => false) }
    let(:images_domain) { instance_double('PhotoFS::ImageSet') }

    before(:example) do
      tag_set.add? PhotoFS::Tag.new('tag1')
      tag_set.add? PhotoFS::Tag.new('tag2')
      allow(tag_dir).to receive(:query_tags).and_return(tag_set.all)

      tag_dir.instance_variable_set(:@images_domain, images_domain)
      allow(images_domain).to receive(:include?).with(node.payload).and_return(true)

      allow(tag_dir).to receive(:images).and_return(PhotoFS::ImageSet.new({:set => []}))
      allow(tag_dir).to receive(:is_tags_root?).and_return(false)
    end

    it 'should apply each query tag to image' do
      tag_set.all.each do |tag|
        expect(tag).to receive(:add).with(node.payload)
      end

      tag_dir.soft_move(node, name)
    end

    context 'when node is a directory' do
      let(:node) { instance_double('PhotoFS::Dir', :directory? => true, :payload => nil) }

      it 'should not be permitted' do
        expect { tag_dir.soft_move(node, name) }.to raise_error(Errno::EPERM)
      end
    end

    context 'when dir is tag root' do
      before(:example) do
        allow(tag_dir).to receive(:is_tags_root?).and_return(true)
      end

      it 'should not be permitted' do
        expect { tag_dir.soft_move(node, name) }.to raise_error(Errno::EPERM)
      end
    end

    context 'when node payload is not in image domain' do
      before(:example) do
        allow(images_domain).to receive(:include?).with(node.payload).and_return(false)
      end

      it 'should not be permitted' do
        expect { tag_dir.soft_move(node, name) }.to raise_error(Errno::EPERM)
      end
    end

    context 'when node payload is already in dir images' do
      before(:example) do
        allow(tag_dir).to receive(:images).and_return(PhotoFS::ImageSet.new({:set => [node.payload]}))
      end

      it 'should not be permitted' do
        expect { tag_dir.soft_move(node, name) }.to raise_error(Errno::EPERM)
      end
    end
  end # :soft_move

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
        expect(PhotoFS::TagDir).to receive(:new).with('c', tags, hash_including(:query_tag_names => ['a', 'b', 'c']))
        expect(PhotoFS::TagDir).to receive(:new).with('d', tags, hash_including(:query_tag_names => ['a', 'b', 'd']))

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
