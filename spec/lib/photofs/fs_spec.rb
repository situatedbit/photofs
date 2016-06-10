require 'photofs/fs'
require 'photofs/fs/test'

describe PhotoFS::FS do
  let(:klass) { PhotoFS::FS }

  describe :find_data_parent_path do
    let(:file_system) { PhotoFS::FS::Test.new({ :dirs => ['/a/b/c/.photofs'], :files => ['/a/b/c/d/image.jpg', '/1/2/3/image.jpg'] }) }

    before(:example) do
      allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
    end

    it 'should raise exception when parent path does not exist' do
      expect { klass.find_data_parent_path('/1/2/3/image.jpg') }.to raise_error(Errno::ENOENT)
    end

    it 'should return the parent path when the path exists' do
      expect(klass.find_data_parent_path '/a/b/c/d/image.jpg').to eq '/a/b/c'
    end
  end # :find_data_parent_path

  describe :nearest_dir do
    let(:file_system) { PhotoFS::FS::Test.new({ :files => ['/a/1.jpg', '/1.jpg'] }) }

    before(:example) do
      allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
    end

    it { expect(klass.nearest_dir '/').to eq('/') }
    it { expect(klass.nearest_dir '/a').to eq('/a') }
    it { expect(klass.nearest_dir '/a/1.jpg').to eq('/a') }
    it { expect(klass.nearest_dir '/1.jpg').to eq('/') }
  end
end
