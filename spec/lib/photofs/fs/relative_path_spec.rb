require 'photofs/fs/relative_path'

describe PhotoFS::FS::RelativePath do
  let(:klass) { PhotoFS::FS::RelativePath }

  describe :new do
    describe 'should normalize leading with first component' do
      it 'for a period' do
        expect(klass.new('.').to_s).to eq('')
      end

      it 'for an empty string' do
        expect(klass.new('').to_s).to eq('')
      end

      it { expect(klass.new('t').to_s).to eq('t') }

      it 'for path component' do
        expect(klass.new('test').to_s).to eq('test')
      end

      it 'for leading /' do
        expect(klass.new('/test').to_s).to eq('test')
      end

      it 'for leading ./' do
        expect(klass.new('./test').to_s).to eq('test')
      end

      it 'for leading .' do
        expect(klass.new('.test').to_s).to eq('.test')
      end
    end
  end

  describe :descend do
    context 'when there is more than one component' do
      let(:path) { klass.new '/first/second/third' }

      it 'returns a path object including all components but the last' do
        expect(path.descend.to_s).to eq('second/third')
      end
    end

    context 'when there are no components' do
      let(:path) { klass.new '/' }

      it 'returns a path object with length of 0' do
        expect(path.descend).to be nil
      end
    end

    context 'when there is one component' do
      let(:path) { klass.new '/help' }

      it 'returns a path referencing this' do
        expect(path.descend.to_s).to eq('')
      end
    end
  end

  describe :top_name do
    context 'when there is more than one component' do
      let(:path) { klass.new '/first/second/third' }

      it 'returns the first child as a string' do
        expect(path.top_name).to eq('first')
      end
    end

    context 'when there are no components' do
      let(:path) { klass.new '/' }

      it 'is nil' do
        expect(path.top_name).to be nil
      end
    end

    context 'when there is one component' do
      let(:path) { klass.new '/help' }

      it 'is the component string' do
        expect(path.top_name).to eq('help')
      end
    end
  end

  describe :length do
    let(:path) { klass.new '/test/path' }

    it 'should return the number of path components' do
      expect(path.send :length).to be 2      
    end
  end

  describe :name do
    context 'if path is empty' do
      let(:path) { klass.new '' }

      it 'should return empty string' do
        expect(path.name).to be_empty
      end
    end

    context 'when there is at least one path component' do
      let(:path) { klass.new '/what/ever' }

      it 'should return the last component' do
        expect(path.name).to eq('ever')
      end
    end
  end

  describe :parent do
    context 'when there is more than one component' do
      let(:path) { klass.new './first/second/third' }

      it 'returns a path object including all components but the last' do
        expect(path.parent.to_s).to eq('first/second')
      end
    end

    context 'when there are two components' do
      let(:path) { klass.new 't/good-something' }

      it 'should be just the top-most component' do
        expect(path.parent.to_s).to eq('t')
      end
    end

    context 'when there are no components' do
      let(:path) { klass.new '/' }

      it 'is nil' do
        expect(path.parent).to be nil
      end
    end

    context 'when there is one component' do
      let(:path) { klass.new '/help' }

      it 'path representing this' do
        expect(path.parent.is_this?).to be true
      end
    end
  end

  describe :is_name? do
    context 'when there is more than one component' do
      let(:path) { klass.new '/first/second/third' }

      it 'should be false' do
        expect(path.is_name?).to be false
      end
    end

    context 'when there are no components' do
      let(:path) { klass.new './' }

      it 'should be true' do
        expect(path.is_name?).to be false
      end
    end

    context 'when there is one component' do
      let(:path) { klass.new './help' }

      it 'should be true' do
        expect(path.is_name?).to be true
      end
    end
  end # :is_name?

  describe :is_this do
    context 'when there is more than one component' do
      let(:path) { klass.new '/first/second/third' }

      it 'is false' do
        expect(path.is_this?).to be false
      end
    end

    context 'when there are no components' do
      let(:path) { klass.new './' }

      it 'is true' do
        expect(path.is_this?).to be true
      end
    end

    context 'when there is one component' do
      let(:path) { klass.new './help' }

      it 'is false' do
        expect(path.is_this?).to be false
      end
    end
  end

  describe :to_s do
    it 'should return normalized original path' do
      expect(klass.new('/what/ever').to_s).to eq('what/ever')
    end
  end
end
