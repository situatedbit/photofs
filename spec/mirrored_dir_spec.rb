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

  describe "initialize method" do
    it "should take a directory target" do
      expect((PhotoFS::MirroredDir.new('test', path)).source_path).to eq(absolute_path)
    end
  end

  describe '#mkdir' do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }

    it 'should just say no' do
      expect { dir.mkdir 'なにか' }.to raise_error(Errno::EPERM)
    end
  end
  
  describe "stat method" do
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

  describe "nodes method" do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }
    let(:file_name) { 'a-file' }
    let(:dir_name) { 'a-dir' }

    context "when there are no files" do
      before(:each) do
        allow(Dir).to receive(:entries).and_return(['.', '..'])
      end

      it "should return an empty collection" do
        expect(dir.nodes).to be_empty
      end
    end

    context "when there is a file in the target dir" do
      before(:each) do
        allow(Dir).to receive(:entries).and_return(['.', '..', file_name])
        allow(File).to receive(:directory?).and_return(false)
      end

      it "should return a file node representing that file" do
        expect(dir.nodes).to contain_exactly(PhotoFS::File.new(file_name, [path, file_name].join(File::SEPARATOR), dir))
      end
    end

    context "when there are files and dirs in target dir" do
      before(:each) do
        allow(Dir).to receive(:entries).and_return(['.', '..', file_name, dir_name])
        allow(File).to receive(:directory?).and_return(false, true)
      end

      it "should return a mirrored dir for each dir, and a file for each file" do
        expect(dir.nodes).to contain_exactly(PhotoFS::File.new(file_name, [path, file_name].join(File::SEPARATOR), dir), PhotoFS::MirroredDir.new(dir_name, [path, dir_name].join(File::SEPARATOR), dir))
      end
    end
  end # nodes method
end
