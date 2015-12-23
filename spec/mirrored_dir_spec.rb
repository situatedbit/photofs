require 'spec_helper'
require 'mirrored_dir'
require 'rfuse'
require 'stat'

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
  
  describe "stat method" do
    let(:dir) { PhotoFS::MirroredDir.new('test', path) }

    before(:each) do
      allow(PhotoFS::Stat).to receive(:stat_hash).and_return({})
      allow(File).to receive(:stat).and_return(nil)
    end

    it "should return read-only" do
      expect(dir.stat.mode & PhotoFS::Stat::MODE_MASK).to eq(PhotoFS::Stat::MODE_READ_ONLY)
    end

    it "should return real directory" do
      expect(dir.stat.mode & RFuse::Stat::S_IFMT).to eq(RFuse::Stat::S_IFDIR)
    end
  end

  describe "nodes method" do
    it "should return file nodes for each real file in target directory" do
    end
  end

  describe "add_node" do
    it "should not be callable, but rather protected" do
    end
  end
end
