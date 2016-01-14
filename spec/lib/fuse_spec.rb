require 'spec_helper'
require 'rfuse'
require 'fuse'

describe PhotoFS::Fuse do
  let(:context) { instance_double('RFuse::Context') }

  describe :readdir do
    let(:fuse) { PhotoFS::Fuse.new({:source => 'source-path', :mountpoint => 'mount-point'}) }
    let(:filler) { instance_double("filler") }
    let(:root_dir) { instance_double('PhotoFS::RootDir') }
    let(:dir) { double('search-dir') }

    before(:example) do
      allow(PhotoFS::RootDir).to receive(:new).and_return(root_dir)
      allow(root_dir).to receive(:add)

      allow(PhotoFS::MirroredDir).to receive(:new) do
        instance_double('PhotoFS::MirroredDir', :directory? => true, :name => 'mirrored-dir')
      end

      allow(fuse).to receive(:log) # swallow log messages
      allow(fuse).to receive(:search).and_return(dir)
    end

    context 'when path is not for a directory' do
      before(:each) do
        allow(dir).to receive(:directory?).and_return(false)
      end

      it 'will throw an error' do
        expect { fuse.readdir(context, 'path', filler, 0, 0) }.to raise_error(Errno::ENOTDIR)
      end
    end

    context 'when path is a directory' do
      let(:node1) { instance_double('PhotoFS::Node', :stat => 'stat1') }
      let(:node2) { instance_double('PhotoFS::Node', :stat => 'stat2') }
      let(:nodes) do
        { 'name-1' => node1, 'name-2' => node2 }
      end

      before(:example) do
        allow(dir).to receive(:directory?).and_return(true)
        allow(dir).to receive(:nodes).and_return(nodes)
      end

      it 'will call filler with names from lookup table' do
        expect(filler).to receive(:push).with('name-1', node1.stat, 0)
        expect(filler).to receive(:push).with('name-2', node2.stat, 0)

        fuse.readdir(context, 'path', filler, 0, 0)
      end

    end
  end
end
