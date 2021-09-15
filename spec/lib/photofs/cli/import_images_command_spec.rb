require 'photofs/cli/import_images_command'
require 'photofs/data/image_set'
require 'photofs/fs/file_monitor'
require 'photofs/fs/test'

describe PhotoFS::CLI::ImportImagesCommand do
  let(:path) { 'a/b/c/' }
  let(:valid_path) { '/a/b/c' }
  let(:command) { PhotoFS::CLI::ImportImagesCommand.new(['import', 'images', path]) }
  let(:file_system) { PhotoFS::FS::Test.new( { files:  [] } )}
  let(:file_monitor) { instance_double('FileMonitor', paths:  ['/a/b/c']) }
  let(:images) { instance_double 'ImageSet' }

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
    allow(PhotoFS::FS).to receive(:images_path).and_return('/arbitrary/root/path')
    allow(PhotoFS::FS::FileMonitor).to receive(:new).and_return(file_monitor)
    allow(PhotoFS::Data::ImageSet).to receive(:new).and_return(images)
  end

  describe :datastore_start_path do
    let(:working_dir) { '/my/working/directory' }

    before(:example) do
      allow(file_system).to receive(:pwd).and_return(working_dir)
    end

    it { expect(command.datastore_start_path).to eq(working_dir) }
  end

  describe :matcher do
    let(:command) { PhotoFS::CLI::ImportImagesCommand }

    it { expect(command.match? ['import', 'images', '.']).to be true }
    it { expect(command.match? ['import', 'images', './some/file/']).to be true }
    it { expect(command.match? ['import', 'images', './some/file']).to be true }
    it { expect(command.match? ['import', 'images', 'some/file']).to be true }
    it { expect(command.match? ['import', 'images', '../some/file']).to be true }
    it { expect(command.match? ['import', 'images', '../some/file', 'another/dir']).to be true }
    it { expect(command.match? ['import', 'images', '../some/file\ spaces']).to be true }

    it { expect(command.match? ['import']).to be false }
    it { expect(command.match? ['import', 'images']).to be false }
    it { expect(command.match? ['something', 'else', 'entirely']).to be false }
  end

  describe :modify_datastore do
    before(:example) do
      allow(images).to receive(:import!).and_return([])
    end

    subject { command.modify_datastore }

    it 'should send the path to file monitor as the search path' do
      expect(PhotoFS::FS::FileMonitor).to receive(:new).with(satisfy { |o| o[:search_path] == path })

      subject
    end

    it 'should send paths from file monitor to image set' do
      expect(images).to receive(:import!).with(file_monitor.paths)

      subject
    end

    context 'when images are imported' do
      before(:example) do
        allow(images).to receive(:import!).and_return([double('an image', path: 'some-path.jpg')])
      end

      it { should be true }
    end

    context 'when images are not imported' do
      before(:example) do
        allow(images).to receive(:import!).and_return([])
      end

      it { should be false }
    end
  end

  describe :validate do
    before(:example) do
      allow(command).to receive(:valid_path).with(path).and_return(valid_path)
    end

    subject { command.validate }

    it { should eq([valid_path]) }
  end
end
