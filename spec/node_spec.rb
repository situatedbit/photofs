require 'spec_helper'
require 'node'

describe PhotoFS::Node do
  it 'should reject a parent that is not a directory' do
    parent = double("non-directory parent")
    allow(parent).to receive(:directory?) { false }
    expect { PhotoFS::Node.new('onarimon', parent) }.to raise_error(ArgumentError)
  end

  describe 'initialize method' do
    it 'should require non-empty name' do
      expect { PhotoFS::Node.new('') }.to raise_error(ArgumentError)
    end
  end

  describe '== method' do
    let(:common_name) { 'a common path' }
    let(:this) { PhotoFS::Node.new(common_name) }
    let(:that) { PhotoFS::Node.new(common_name) }

    before(:each) do
      allow(this).to receive(:path).and_return(common_name)
      allow(that).to receive(:path).and_return(common_name)
    end

    context 'when two nodes have the same path' do
      it 'should return true' do
        expect(this == that).to be true
      end
    end

    context 'when other is not a node' do
      let(:a_string) { 'a string' }

      it 'should return false' do
        expect(this == a_string).to be false
      end
    end

    context 'when other has a different path' do
      before(:each) do
        allow(that).to receive(:path).and_return(common_name * 2)
      end

      it 'should return false' do
        expect(this == that).to be false
      end
    end
  end # == method

  describe 'top-level instance' do
    let(:name) { 'otemachi' }
    let(:node) { PhotoFS::Node.new name }

    it 'should have no parent' do
      expect(node.parent).to be nil
    end

    it 'should have a name' do
      expect(node.name).to eq('otemachi')
    end

    it 'should have a very short path' do
      expect(node.path).to eq(File::SEPARATOR + name)
    end

    it 'should not be a directory' do
      expect(node.directory?).to be false
    end

    it 'should not have a stat' do
      expect(node.stat).to be nil
    end

    describe 'and second-level instance' do
      let(:second_name) { 'tokyo' }
      let(:second_node) { PhotoFS::Node.new(second_name, node) }

      before(:each) do
        allow(node).to receive(:directory?) { true }
      end

      it 'should have a parent' do
        expect(second_node.parent).to eq(node)
      end

      it 'should include parent in path' do
        expect(second_node.path).to eq([node.path, second_name].join(File::Separator))
      end
    end
  end
end
