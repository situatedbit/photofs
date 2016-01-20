require 'spec_helper'
require 'mirrored_dir'
require 'file'

describe PhotoFS::MirroredDir do
  let(:absolute_path) { '/tmp/garbage' }
  let(:path) { 'garbage' }

  before(:each) do
    allow(File).to receive(:absolute_path) { absolute_path }
    allow(File).to receive(:exist?) { true }
  end

  describe :new do
    let(:options) { {} }
    let(:default_options) { {:default => 'some-default'} }

    it "should take a directory target" do
      expect((PhotoFS::MirroredDir.new('test', path)).source_path).to eq(absolute_path)
    end

    it 'should merge optional arguments' do
      PhotoFS::MirroredDir.new('test', path)
    end

    it 'should merge options with default options' do
      options[:special] = 'option'

      allow_any_instance_of(PhotoFS::MirroredDir).to receive(:default_options).and_return(default_options)

      dir = PhotoFS::MirroredDir.new 'test', path, options

      expect(dir.instance_variable_get(:@options)[:default]).to eq(default_options[:default])
      expect(dir.instance_variable_get(:@options)[:special]).to eq(options[:special])
    end
  end

  describe '#mkdir' do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }

    it 'should just say no' do
      expect { dir.mkdir 'なにか' }.to raise_error(Errno::EPERM)
    end
  end

  describe '#rmdir' do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }

    it 'should just say no' do
      expect { dir.rmdir 'なにか' }.to raise_error(Errno::EPERM)
    end
  end

  describe :stat do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }

    before(:each) do
      allow(PhotoFS::Stat).to receive(:stat_hash).and_return({})
      allow(File).to receive(:stat).and_return({})
    end

    it "should return read-only" do
      expect(dir.stat.mode & PhotoFS::Stat::MODE_MASK).to eq(PhotoFS::Stat::MODE_READ_ONLY)
    end

    it "should return real directory" do
      expect(dir.stat.mode & RFuse::Stat::S_IFMT).to eq(RFuse::Stat::S_IFDIR)
    end
  end

  describe :node_hash do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }
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
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }
    let(:file_name) { 'a-file' }
    let(:dir_name) { 'a-dir' }

    context "when there are no files" do
      before(:example) do
        allow(Dir).to receive(:entries).and_return(['.', '..'])
      end

      it "should be empty" do
        expect(dir.send(:node_hash).values).to be_empty
      end
    end

    context "when there is a file in the target dir" do
      before(:each) do
        allow(Dir).to receive(:entries).and_return(['.', '..', file_name])
        allow(File).to receive(:directory?).and_return(false)
      end

      it "should be a file node representing that file" do
        expect((dir.send :node_hash).values).to contain_exactly(PhotoFS::File.new(file_name, [path, file_name].join(File::SEPARATOR), {:parent => dir}))
      end
    end

    context "when there are files and dirs in target dir" do
      let(:node_hash) do
        [PhotoFS::File.new(file_name, [path, file_name].join(File::SEPARATOR), {:parent => dir}),
         PhotoFS::MirroredDir.new(dir_name, [path, dir_name].join(File::SEPARATOR), {:parent => dir})]
      end

      before(:each) do
        allow(Dir).to receive(:entries).and_return(['.', '..', file_name, dir_name])
        allow(File).to receive(:directory?).and_return(false, true)
      end

      it "should be a mirrored dir for each dir and a file for each file" do
        expect((dir.send :node_hash).values).to contain_exactly(*node_hash)
      end
    end
  end

  describe :tags_node do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }

    context 'when there is no tag set' do
      before(:example) do
        dir.instance_variable_set(:@tags, nil)
      end

      it 'should be empty' do
        expect(dir.send :tags_node).to be_empty
      end
    end

    context 'when there is a tag set' do
      let(:tags) { instance_double('PhotoFS::TagSet') }
      let(:tag_dir) { instance_double('PhotoFS::TagDir', :name => 'tags') }

      before(:example) do
        dir.instance_variable_set(:@tags, tags)

        allow(PhotoFS::TagDir).to receive(:new).and_return(tag_dir)
      end

      it 'should contain a new tag dir' do
        expect(dir.send(:tags_node).values).to contain_exactly(tag_dir)
      end

      it 'should set self as parent' do
        expect(PhotoFS::TagDir).to receive(:new).with('tags', tags, {:parent => dir})

        dir.send :tags_node
      end
    end
  end # :tags_node
end
