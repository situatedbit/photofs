require 'photofs/fs/test'
require 'photofs/cli/prune_command'

describe PhotoFS::CLI::PruneCommand do
  let(:klass) { PhotoFS::CLI::PruneCommand }
  let(:path_arg) { '/a/b/c' }
  let(:command) { PhotoFS::CLI::PruneCommand.new(['prune', path_arg]) }

  let(:file_system) { PhotoFS::FS::Test.new( { :files => [path_arg] } )}

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)

    allow(command).to receive(:initialize_datastore) # swallow
  end

  describe :datastore_start_path do
    before(:each) do
      allow(PhotoFS::FS).to receive(:nearest_dir).with(path_arg).and_return('/a/b')

      command.validate
    end

    it { expect(command.datastore_start_path).to eq('/a/b') }
  end

  describe :matcher do
    it { expect(klass.match? ['prune', '/some/file/somewhere']).to be true }
    it { expect(klass.match? ['prune', '.']).to be true }
    it { expect(klass.match? ['prune', './']).to be true }
    it { expect(klass.match? ['prune', '/']).to be true }
    it { expect(klass.match? ['prune', './some/file.jpg']).to be true }
    it { expect(klass.match? ['something-else', './some/file.jpg']).to be false }
    it { expect(klass.match? ['prune']).to be false }
  end

  describe :modify_datastore do
    let(:f1) { '/a/b/c/2.jpg' }
    let(:f2) { '/a/b/1.jpg' }
    let(:f3) { '/a/0.jpg' }

    let(:i1) { double('Image', :path => f1) }
    let(:i2) { double('Image', :path => f2) }
    let(:i3) { double('Image', :path => f3) }

    let(:image_set) { double('ImageSet') }

    before(:each) do
      command.instance_variable_set(:@images, image_set)
      command.instance_variable_set(:@prune_path, path_arg)

      allow(image_set).to receive(:find_by_path_parent).with(path_arg).and_return([i1, i2, i3])
    end

    context 'when all images under path exist' do
      before(:each) do
        [f1, f2, f3].each { |f| allow(file_system).to receive(:exist?).with(f).and_return(true) }
      end

      let(:path_arg) { '/a' }

      it 'should not remove any images' do
        allow(command).to receive(:puts)
        expect(image_set).not_to receive(:remove)

        command.modify_datastore
      end

      it 'should report not removing any images' do
        expect { command.modify_datastore }.to output(/No images to prune/).to_stdout
      end
    end

    context 'when some images do not exist under the path' do
      before(:each) do
        allow(file_system).to receive(:exist?).with(f1).and_return(true)
        allow(image_set).to receive(:remove)

        [f2, f3].each { |f| allow(file_system).to receive(:exist?).with(f).and_return(false) }
      end

      it 'should remove files from database that do not exist under path' do
        allow(command).to receive(:puts)
        expect(image_set).to receive(:remove).with(i2)
        expect(image_set).to receive(:remove).with(i3)

        command.modify_datastore
      end

      it 'should report the files removed' do
        expect { command.modify_datastore }.to output(/#{f2}/).to_stdout
      end
    end
  end # :modify_datastore

  describe :validate do
    before(:example) do
      allow(command).to receive(:valid_path).with(path_arg).and_return(path_arg)
      allow(PhotoFS::FS).to receive(:nearest_dir).with(path_arg).and_return('/')
    end

    subject { command.validate }

    it { should eq('/') }
  end
end
