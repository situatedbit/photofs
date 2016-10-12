require 'photofs/core/tag_set'
require 'photofs/fs'
require 'photofs/fs/test'
require 'photofs/fuse/file'
require 'photofs/fuse/tag_dir'
require 'photofs/fuse/stat'

describe PhotoFS::Fuse::TagDir do
  describe :new do
    let(:parent) { PhotoFS::Fuse::Dir.new 'お母さん' }
    let(:query_tag_names) { ['query', 'tag', 'names'] }
    let(:default_options) { {:query_tag_names => ['deafult', 'tag', 'names']} }

    it 'should take an optional parent' do
      dir = PhotoFS::Fuse::TagDir.new('name', {}, {:parent => parent})

      expect(dir.instance_variable_get(:@parent)).to be parent
    end

    it 'should take optional query_tag_names' do
      dir = PhotoFS::Fuse::TagDir.new('name', {}, {:query_tag_names => query_tag_names})

      expect(dir.instance_variable_get(:@query_tag_names)).to be query_tag_names
    end

    it 'should merge options with defaults' do
      options = {:special => 'option'}

      allow_any_instance_of(PhotoFS::Fuse::TagDir).to receive(:default_options).and_return(default_options)

      dir = PhotoFS::Fuse::TagDir.new 'name', {}, options

      expect(dir.instance_variable_get(:@query_tag_names)).to eq(default_options[:query_tag_names])
      expect(dir.instance_variable_get(:@options)[:special]).to eq(options[:special])
    end
  end

  describe :add do
    let(:query_tag_names) { ['tag1', 'tag2'] }
    let(:payload) { 'the image' }
    let(:node) { instance_double('PhotoFS::Node', :name => '子供', :path => 'garbage', :payload => payload) }
    let(:dir) { PhotoFS::Fuse::TagDir.new 'じしょ' , {}, {:query_tag_names => query_tag_names}}
    let(:images_domain) { instance_double('PhotoFS::Core:;ImageSet') }

    before(:example) do
      dir.instance_variable_set(:@images_domain, images_domain)

      allow(dir).to receive(:images).and_return(double('images', {:include? => false}))
    end

    context 'when node payload is already in images set' do
      before(:example) do
        allow(dir).to receive(:images).and_return(double('images', {:include? => true}))
      end

      it 'should not be permitted' do
        expect { dir.add('child', node) }.to raise_error(Errno::EEXIST)
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
      let(:tag_a) { instance_double('PhotoFS::Core::Tag') }
      let(:tag_b) { instance_double('PhotoFS::Core::Tag') }

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
    let(:tag_dir) { PhotoFS::Fuse::TagDir.new('t', PhotoFS::Core::TagSet.new) }

    it { expect { tag_dir.mkdir 'new-dir' }.to raise_error(Errno::EPERM) }
  end

  describe :remove do
    let(:dir) { PhotoFS::Fuse::TagDir.new 'じしょ' , {}, {:query_tag_names => []}}

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
      let(:tag_a) { instance_double('PhotoFS::Core::Tag', :name => 'good') }
      let(:image) { instance_double('PhotoFS::Core::Image') }
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
        let(:tag_b) { instance_double('PhotoFS::Core::Tag', :name => 'bad') }
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
    # this doesn't make sense; you'd delete all of the
    # children first, once that happens, this dir ceases to exist.
    let(:dir) { PhotoFS::Fuse::TagDir.new('t', double('TagSet')) }

    it { expect { dir.rmdir 'tag-name' }.to raise_error(Errno::EPERM) }
  end

  describe :soft_move do
    let(:tag_set) { PhotoFS::Core::TagSet.new }
    let(:tag_dir) { PhotoFS::Fuse::TagDir.new('日本橋', tag_set) }
    let(:name) { 'new name' }
    let(:node) { instance_double('PhotoFS::File', :payload => 'node-payload', :directory? => false) }
    let(:images_domain) { instance_double('PhotoFS::Core::ImageSet') }

    before(:example) do
      tag_set.add? PhotoFS::Core::Tag.new('tag1')
      tag_set.add? PhotoFS::Core::Tag.new('tag2')
      allow(tag_dir).to receive(:query_tags).and_return(tag_set.all)

      tag_dir.instance_variable_set(:@images_domain, images_domain)
      allow(images_domain).to receive(:include?).with(node.payload).and_return(true)

      allow(tag_dir).to receive(:images).and_return(PhotoFS::Core::ImageSet.new({:set => []}))
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
        allow(tag_dir).to receive(:images).and_return(PhotoFS::Core::ImageSet.new({:set => [node.payload]}))
      end

      it 'should not be permitted' do
        expect { tag_dir.soft_move(node, name) }.to raise_error(Errno::EPERM)
      end
    end
  end # :soft_move

  describe :stat do
    let(:tag_dir) { PhotoFS::Fuse::TagDir.new('nihonbashi', PhotoFS::Core::TagSet.new) }

    it 'should return writable by owner' do
      expect(tag_dir.stat.mode & PhotoFS::Fuse::Stat::MODE_MASK & PhotoFS::Fuse::Stat::PERM_USER_WRITE).to be PhotoFS::Fuse::Stat::PERM_USER_WRITE
    end

    it 'should include size' do
      expect(tag_dir.stat.size).to be 1024
    end
  end # :stat

  describe :symlink do
    let(:tag_dir) { PhotoFS::Fuse::TagDir.new('日本', PhotoFS::Core::TagSet.new, { :query_tag_names => ['first', 'second'] }) }
    let(:name) { 'some.jpg' }
    let(:image) { instance_double('PhotoFS::Core::Image') }
    let(:images_domain) { instance_double('PhotoFS::Core::ImageSet') }

    before(:example) do
      tag_dir.instance_variable_set(:@images_domain, images_domain)
    end

    context 'when image is not in tag image set' do
      before(:example) do
        allow(images_domain).to receive(:include?).with(image).and_return(false)
      end

      it 'should not be permitted' do
        expect { tag_dir.symlink(image, name) }.to raise_error(Errno::EPERM)
      end
    end

    context 'when image is in the tag image set' do
      let(:tag1) { instance_double('PhotoFS::Core::Tag') }
      let(:tag2) { instance_double('PhotoFS::Core::Tag') }
      let(:query_tags) { [tag1, tag2] }

      before(:example) do
        allow(images_domain).to receive(:include?).with(image).and_return(true)
        allow(tag_dir).to receive(:query_tags).and_return(query_tags)
      end

      it 'should apply all tags in query list to image' do
        expect(tag1).to receive(:add).with(image)
        expect(tag2).to receive(:add).with(image)

        tag_dir.symlink(image, name)
      end
    end
  end # :symlink

  describe :node_hash do
    let(:tag_dir) { PhotoFS::Fuse::TagDir.new('nihonbashi', PhotoFS::Core::TagSet.new) }

    context 'when there are no files or dirs' do
      before(:example) do
        allow(tag_dir).to receive(:files).and_return({})
        allow(tag_dir).to receive(:dirs).and_return({})
      end

      it 'should return an empty hash' do
        expect(tag_dir.send :node_hash).to eq({})
      end
    end

    context 'when there are files and dirs' do
      let(:node_class) { Struct.new(:name) }
      let(:files) { {'first' => node_class.new('first'), 'second' => node_class.new('second')} }
      let(:dirs) { {'third' => node_class.new('third'), 'fourth' => node_class.new('fourth')} }

      let(:node_hash) { files.merge dirs }

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
    let(:tag_dir) { PhotoFS::Fuse::TagDir.new('nihonbashi', PhotoFS::Core::TagSet.new) }

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
      let(:tags) { PhotoFS::Core::TagSet.new }

      before(:example) do
        tag_dir.instance_variable_set(:@tags, tags)
        tag_dir.instance_variable_set(:@query_tag_names, query_tag_names)

        allow(tag_dir).to receive(:dir_tags).and_return(dir_tags)
      end

      it 'should return a new collection with a tag_dir with combined query tags' do
        expect(PhotoFS::Fuse::TagDir).to receive(:new).with('c', tags, hash_including(:query_tag_names => ['a', 'b', 'c']))
        expect(PhotoFS::Fuse::TagDir).to receive(:new).with('d', tags, hash_including(:query_tag_names => ['a', 'b', 'd']))

        tag_dir.send :dirs
      end
    end
  end

  describe :files do
    let(:tag_dir) { PhotoFS::Fuse::TagDir.new('日本橋', PhotoFS::Core::TagSet.new) }

    let(:image_a) { instance_double('PhotoFS::Core::Image', :path => 'a/え.jpg') }
    let(:image_b) { instance_double('PhotoFS::Core::Image', :path => 'b/え.jpg') }
    let(:image_c) { instance_double('PhotoFS::Core::Image', :path => 'c/え.jpg') }
    let(:image_d) { instance_double('PhotoFS::Core::Image', :path => 'd/きれい.jpg') }

    let(:images) { PhotoFS::Core::ImageSet.new :set => [image_a, image_d].to_set }
    let(:additional_files) { {'some-other-file' => double('File')} }
    let(:files) { ['some-other-file', 'え.jpg', 'きれい.jpg'] }

    before(:example) do
      allow(tag_dir).to receive(:images).and_return(images)
      allow(tag_dir).to receive(:additional_files).and_return(additional_files)
      allow(PhotoFS::FS).to receive(:images_path).and_return('/home/usr/photos')
      allow(PhotoFS::FS).to receive(:file_system).and_return(PhotoFS::FS::Test.new)
    end

    it 'should return hash of files' do
      expect(tag_dir.send(:files).keys).to include *files
    end

    context 'when there are name collisions' do
      let(:images) { PhotoFS::Core::ImageSet.new :set => [image_c, image_b, image_a].to_set }

      let(:files) { ['え.jpg', 'え-b.jpg', 'え-c.jpg'] }

      it 'should use the base name for the first instance of that file name and uniqe names for all others' do
        expect(tag_dir.send(:files).keys).to include *files
      end
    end
  end # :files

end
