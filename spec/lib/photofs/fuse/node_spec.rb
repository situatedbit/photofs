require 'photofs/fuse/node'

describe PhotoFS::Fuse::Node do
  describe :new do
    let(:options) { Hash.new }
    let(:name) { 'onarimon' }
    let(:default_options) { { :default => 'option' } }

    it 'should initialize with just a name' do
      expect { PhotoFS::Fuse::Node.new name }.not_to raise_error
    end

    it 'should take an options parameter' do
      options[:test] = 'test'

      node = PhotoFS::Fuse::Node.new name, options

      expect(node.instance_variable_get(:@options)[:test]).to eq('test')
    end

    it 'should merge options with default options' do
      options[:special] = 'option'

      allow_any_instance_of(PhotoFS::Fuse::Node).to receive(:default_options).and_return(default_options)

      node = PhotoFS::Fuse::Node.new name, options

      expect(node.instance_variable_get(:@options)[:default]).to eq(default_options[:default])
      expect(node.instance_variable_get(:@options)[:special]).to eq(options[:special])
    end

    it 'should reject a parent that is not a directory' do
      parent = double("non-directory parent")

      allow(parent).to receive(:directory?) { false }

      expect { PhotoFS::Fuse::Node.new('onarimon', { parent: parent }) }.to raise_error(ArgumentError)
    end
  end

  describe :== do
    let(:payload) { 'a common path' }
    let(:this) { PhotoFS::Fuse::Node.new('path-b') }
    let(:that) { PhotoFS::Fuse::Node.new('path-a') }

    before(:each) do
      allow(this).to receive(:payload).and_return(payload)
      allow(that).to receive(:payload).and_return(payload)
    end

    context 'when two nodes have the same payload' do
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

    context 'when other has a different payload' do
      before(:example) do
        allow(that).to receive(:payload).and_return(payload * 2)
      end

      it 'should return false' do
        expect(this == that).to be false
      end
    end
  end # :==

  describe :payload do
    let(:path) { 'some-path' }
    let(:node) { PhotoFS::Fuse::Node.new('blah') }

    before(:example) do
      allow(node).to receive(:path).and_return(path)
    end

    it 'should be the path' do
      expect(node.payload).to eq(path)
    end
  end

  describe 'top-level instance' do
    let(:name) { 'otemachi' }
    let(:node) { PhotoFS::Fuse::Node.new name }

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
      let(:second_node) { PhotoFS::Fuse::Node.new(second_name, {parent: node}) }

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
