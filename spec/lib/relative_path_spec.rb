require 'spec_helper'
require 'relative_path'

describe PhotoFS::RelativePath do
  describe "#new" do
    describe 'should normalize leading ./' do
      it 'for a period' do
        expect(PhotoFS::RelativePath.new('.').to_s).to eq('./')
      end

      it 'for an empty string' do
        expect(PhotoFS::RelativePath.new('').to_s).to eq('./')
      end

      it 'for path component' do
        expect(PhotoFS::RelativePath.new('test').to_s).to eq('./test')
      end

      it 'for leading /' do
        expect(PhotoFS::RelativePath.new('/test').to_s).to eq('./test')
      end

      it 'for leading ./' do
        expect(PhotoFS::RelativePath.new('./test').to_s).to eq('./test')
      end

      it 'for leading .' do
        expect(PhotoFS::RelativePath.new('.test').to_s).to eq('./.test')
      end
    end
  end

  describe '#follow_first' do
    context 'when there is more than one component' do
      let(:path) { PhotoFS::RelativePath.new '/first/second/third' }

      it 'returns a path object including all components but the last' do
        expect(path.follow_first.to_s).to eq('./second/third')
      end
    end

    context 'when there are no components' do
      let(:path) { PhotoFS::RelativePath.new '/' }

      it 'returns a path object with length of 0' do
        expect(path.follow_first).to be nil
      end
    end

    context 'when there is one component' do
      let(:path) { PhotoFS::RelativePath.new '/help' }

      it 'returns a path referencing this' do
        expect(path.follow_first.to_s).to eq('./')
      end
    end
  end

  describe '#first_name' do
    context 'when there is more than one component' do
      let(:path) { PhotoFS::RelativePath.new '/first/second/third' }

      it 'returns the first child as a string' do
        expect(path.first_name).to eq('first')
      end
    end

    context 'when there are no components' do
      let(:path) { PhotoFS::RelativePath.new '/' }

      it 'is nil' do
        expect(path.first_name).to be nil
      end
    end

    context 'when there is one component' do
      let(:path) { PhotoFS::RelativePath.new '/help' }

      it 'is the component string' do
        expect(path.first_name).to eq('help')
      end
    end
  end

  describe '#length' do
    let(:path) { PhotoFS::RelativePath.new '/test/path' }

    it 'should return the number of path components' do
      expect(path.send :length).to be 2      
    end
  end

  describe '#name' do
    context 'if path is empty' do
      let(:path) { PhotoFS::RelativePath.new '' }

      it 'should return empty string' do
        expect(path.name).to be_empty
      end
    end

    context 'when there is at least one path component' do
      let(:path) { PhotoFS::RelativePath.new '/what/ever' }

      it 'should return the last component' do
        expect(path.name).to eq('ever')
      end
    end
  end

  describe '#parent' do
    context 'when there is more than one component' do
      let(:path) { PhotoFS::RelativePath.new './first/second/third' }

      it 'returns a path object including all components but the last' do
        expect(path.parent.to_s).to eq('./first/second')
      end
    end

    context 'when there are no components' do
      let(:path) { PhotoFS::RelativePath.new '/' }

      it 'is nil' do
        expect(path.parent).to be nil
      end
    end

    context 'when there is one component' do
      let(:path) { PhotoFS::RelativePath.new '/help' }

      it 'path representing this' do
        expect(path.parent.is_this?).to be true
      end
    end
  end

  describe '#is_this?' do
    context 'when there is more than one component' do
      let(:path) { PhotoFS::RelativePath.new '/first/second/third' }

      it 'is false' do
        expect(path.is_this?).to be false
      end
    end

    context 'when there are no components' do
      let(:path) { PhotoFS::RelativePath.new './' }

      it 'is true' do
        expect(path.is_this?).to be true
      end
    end

    context 'when there is one component' do
      let(:path) { PhotoFS::RelativePath.new './help' }

      it 'is false' do
        expect(path.is_this?).to be false
      end
    end
  end

  describe '#to_s' do
    let(:path_s) { '/what/ever' }
    let(:path) { PhotoFS::RelativePath.new path_s }

    it 'should return normalized original path' do
      expect(path.to_s).to eq('.' + path_s)
    end
  end
end
