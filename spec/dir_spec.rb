require 'spec_helper'
require 'dir'

describe PhotoFS::Dir do
  let(:name) { 'iidabashi' }
  let(:dir) { PhotoFS::Dir.new name }

  describe 'top-level instance' do
    it 'should have a name' do
      expect(dir.name).to eq(name)
    end

    it 'should not have a parent' do
      expect(dir.parent).to be nil
    end

    it 'should be a directory' do
      expect(dir.directory?).to be true
    end

    it 'should not have any nodes' do
      expect(dir.nodes).to be_empty
    end

    it 'should not have any node names' do
      expect(dir.node_names).to be_empty
    end

  end # top level instance
end
