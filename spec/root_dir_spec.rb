require 'spec_helper'
require 'root_dir'
require 'node'

describe PhotoFS::RootDir do
  let(:root) { PhotoFS::RootDir.new }

  describe "#add" do
    let(:dir) { PhotoFS::Dir.new('test') }

    it 'sould only accept directories' do
      expect { root.add PhotoFS::Node.new('bad!') }.to raise_error(ArgumentError)
    end

    it 'should set the parent on the dir' do
      expect(dir).to receive(:parent=).with(root)

      root.add(dir)
    end

    it 'should add the dir to nodes collection' do
      root.add(dir)

      expect(root.instance_variable_get(:@nodes)[dir.name]).to be dir
    end
  end

  describe '#mkdir' do
    it 'should just say no' do
      expect { root.mkdir 'anything' }.to raise_error(Errno::EPERM)
    end
  end
end
