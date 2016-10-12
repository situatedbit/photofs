require 'photofs/fuse/mirrored_dir'
require 'photofs/fuse/file'
require 'photofs/fs/test'

describe PhotoFS::Fuse::MirroredDir do
  let(:images_path) { '/home/usr/photos' }
  let(:path) { 'photos' }
  let(:fs) { PhotoFS::FS::Test.new({ :dirs => [images_path], :files => [], :absolute_paths => {path => images_path} }) }

  before(:each) do
    allow(PhotoFS::FS).to receive(:images_path).and_return(images_path)
    allow(PhotoFS::FS).to receive(:file_system).and_return(fs)
    allow(fs).to receive(:exist?).and_return(true)
  end

  describe :images do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }
    let(:path1) { 'path-1' }
    let(:path2) { 'path-2' }
    let(:entries) { [path1, path2] }
    let(:images_domain) { PhotoFS::Core::ImageSet.new }

    before(:each) do
      allow(dir).to receive(:entries).and_return(entries)
      allow(dir).to receive(:expand_path).with(path1).and_return("#{images_path}/#{path1}")
      allow(dir).to receive(:expand_path).with(path2).and_return("#{images_path}/#{path2}")

      allow(images_domain).to receive(:find_by_path).with(path1).and_return(path1)
      allow(images_domain).to receive(:find_by_path).with(path2).and_return(nil)
      dir.instance_variable_set(:@images_domain, images_domain)
    end

    it 'should only include images with paths in the images domain' do
      expect(dir.send :images).to contain_exactly(path1)
    end
  end

  describe :new do
    let(:options) { {} }
    let(:default_options) { {:default => 'some-default'} }

    it "should take a directory target" do
      expect((PhotoFS::Fuse::MirroredDir.new('test', path)).source_path).to eq(images_path)
    end

    it 'should merge optional arguments' do
      PhotoFS::Fuse::MirroredDir.new('test', path)
    end

    it 'should merge options with default options' do
      options[:special] = 'option'

      allow_any_instance_of(PhotoFS::Fuse::MirroredDir).to receive(:default_options).and_return(default_options)

      dir = PhotoFS::Fuse::MirroredDir.new 'test', path, options

      expect(dir.instance_variable_get(:@options)[:default]).to eq(default_options[:default])
      expect(dir.instance_variable_get(:@options)[:special]).to eq(options[:special])
    end
  end

  describe :mkdir do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }

    it 'should just say no' do
      expect { dir.mkdir 'なにか' }.to raise_error(Errno::EPERM)
    end
  end

  describe :rename do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }
    let(:from_name) { 'from' }
    let(:to_name) { 'to' }
    let(:parent_node) { instance_double('PhotoFS::Fuse::Dir') }

    context 'when from_name is not in dir' do
      before(:example) do
        allow(dir).to receive(:node_hash).and_return({})
      end

      it 'should return ENOEXIST error' do
        expect { dir.rename from_name, parent_node, to_name }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when from_name is in dir' do
      let(:from_node) { instance_double('PhotoFS::Fuse::Node') }

      before(:example) do
        allow(dir).to receive(:node_hash).and_return({from_name => from_node})
      end

      it 'should send :soft_move to to_parent' do
        expect(parent_node).to receive(:soft_move).with(from_node, to_name)

        dir.rename from_name, parent_node, to_name
      end
    end
  end # :rename

  describe :rmdir do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }

    it 'should just say no' do
      expect { dir.rmdir 'なにか' }.to raise_error(Errno::EPERM)
    end
  end

  describe :stat do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }

    before(:each) do
      allow(PhotoFS::Fuse::Stat).to receive(:stat_hash).and_return({})
      allow(File).to receive(:stat).and_return({})
    end

    it "should return read-only" do
      expect(dir.stat.mode & PhotoFS::Fuse::Stat::MODE_MASK).to eq(PhotoFS::Fuse::Stat::MODE_READ_ONLY)
    end

    it "should return real directory" do
      expect(dir.stat.mode & RFuse::Stat::S_IFMT).to eq(RFuse::Stat::S_IFDIR)
    end
  end

  describe :node_hash do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }
    let(:tags_node) { Hash.new }
    let(:mirrored_nodes) { Hash.new }

    before(:example) do
      allow(dir).to receive(:tags_node).and_return(tags_node)
      allow(dir).to receive(:mirrored_nodes).and_return(mirrored_nodes)
    end

    it 'should be mirrored nodes merged with tags node' do
      expect(mirrored_nodes).to receive(:merge).with(tags_node)

      dir.send :node_hash
    end
  end # :node_hash

  describe :mirrored_nodes do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }
    let(:file_name) { 'a-file' }
    let(:dir_name) { 'a-dir' }

    context "when there are no files" do
      before(:example) do
        allow(fs).to receive(:entries).and_return(['.', '..'])
      end

      it "should be empty" do
        expect(dir.send(:node_hash).values).to be_empty
      end
    end

    context "when there is a file in the target dir" do
      before(:each) do
        allow(fs).to receive(:entries).and_return(['.', '..', file_name])
        allow(fs).to receive(:directory?).and_return(false)
        fs.add({:images_paths => { file_name => ::File.join(images_path, file_name)}})
      end

      it "should be a file node representing that file" do
        expect((dir.send :node_hash).values).to contain_exactly(PhotoFS::Fuse::File.new(file_name, [path, file_name].join(File::SEPARATOR), {:parent => dir}))
      end
    end

    context "when there are files and dirs in target dir" do
      let(:node_hash) do
        [PhotoFS::Fuse::File.new(file_name, [path, file_name].join(File::SEPARATOR), {:parent => dir}),
         PhotoFS::Fuse::MirroredDir.new(dir_name, [path, dir_name].join(File::SEPARATOR), {:parent => dir})]
      end

      before(:each) do
        allow(fs).to receive(:entries).and_return(['.', '..', file_name, dir_name])
        allow(fs).to receive(:directory?).and_return(false, true)
        fs.add({:images_paths => { file_name => ::File.join(images_path, file_name), dir_name => ::File.join(images_path, dir_name)}})
      end

      it "should be a mirrored dir for each dir and a file for each file" do
        expect((dir.send :node_hash).values).to contain_exactly(*node_hash)
      end
    end
  end

  describe :tags_node do
    let(:dir) { PhotoFS::Fuse::MirroredDir.new('test', path) }

    context 'when there is no tag set' do
      before(:example) do
        dir.instance_variable_set(:@tags, nil)
      end

      it 'should be empty' do
        expect(dir.send :tags_node).to be_empty
      end
    end

    context 'when there is a tags set but no images in the dir' do
      let(:tags) { instance_double('PhotoFS::Core::TagSet') }

      before(:example) do
        dir.instance_variable_set(:@tags, tags)
        allow(dir).to receive(:images).and_return([])
      end

      it 'should not exist' do
        expect(dir.send :tags_node).to be_empty
      end
    end

    context 'when there is a tags set and images in the dir' do
      let(:tags) { instance_double('PhotoFS::Core::TagSet') }
      let(:tag_dir) { instance_double('PhotoFS::Fuse::TagDir', :name => 'tags') }
      let(:images) { [instance_double('PhotoFS::Core::Image')] }

      before(:example) do
        dir.instance_variable_set(:@tags, tags)

        allow(PhotoFS::Fuse::TagDir).to receive(:new).and_return(tag_dir)
        allow(dir).to receive(:images).and_return(images)
      end

      it 'should contain a new tag dir' do
        expect(dir.send(:tags_node).values).to contain_exactly(tag_dir)
      end

      it 'should set self as parent' do
        expect(PhotoFS::Fuse::TagDir).to receive(:new).with('tags', tags, hash_including(:parent => dir))

        dir.send :tags_node
      end

      it 'should set an image set' do
        expect(PhotoFS::Fuse::TagDir).to receive(:new).with('tags', tags, hash_including(:images))

        dir.send :tags_node
      end
    end
  end # :tags_node
end
