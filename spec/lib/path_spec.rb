require 'spec_helper'
require 'path'

describe PhotoFS::Path do
  describe "#new" do
    it 'should reject paths not starting with /' do
      expect { PhotoFS::Path.new 'string' }.to raise_error(ArgumentError)
    end

    it 'should accept empty strings' do
      expect { PhotoFS::Path.new '' }.not_to raise_error
    end
  end

  describe '#length' do
    let(:path) { PhotoFS::Path.new '/test/path' }

    it 'should return the number of path components' do
      expect(path.length).to be 2      
    end
  end

  describe '#name' do
    context 'if path is empty' do
      let(:path) { PhotoFS::Path.new '' }

      it 'should return empty string' do
        expect(path.to_s).to be_empty
      end
    end

    context 'when there is at least one path component' do
      let(:path) { PhotoFS::Path.new '/what/ever' }

      it 'should return the last component' do
        expect(path.name).to eq('ever')
      end
    end
  end

  describe '#parent_path' do
    context 'when there is more than one component' do
      let(:path) { PhotoFS::Path.new '/first/second/third' }

      it 'returns a path object including all components but the last' do
        expect(path.parent_path.to_s).to eq('/first/second')
      end
    end

    context 'when there are no components' do
      let(:path) { PhotoFS::Path.new '/' }

      it 'returns a path object with length of 0' do
        expect(path.parent_path.length).to be 0
      end
    end

    context 'when there is one component' do
      let(:path) { PhotoFS::Path.new '/help' }

      it 'returns a path object with length of 0' do
        expect(path.parent_path.length).to be 0
      end
    end
  end

  describe '#to_s' do
    let(:path_s) { '/what/ever' }
    let(:path) { PhotoFS::Path.new path_s }

    it 'should return original path' do
      expect(path.to_s).to be(path_s)
    end
  end
end
