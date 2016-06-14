require 'photofs/cli/import_command'
require 'photofs/data/image_set'
require 'photofs/fs/file_monitor'
require 'photofs/fs/test'

describe PhotoFS::CLI::ImportCommand do
  let(:klass) { PhotoFS::CLI::ImportCommand }
  let(:path) { 'a/b/c/' }
  let(:valid_path) { '/a/b/c' }
  let(:command) { PhotoFS::CLI::ImportCommand.new(['import', path]) }
  let(:file_system) { PhotoFS::FS::Test.new( { :files => [] } )}
  let(:file_monitor) { instance_double('FileMonitor', :paths => []) }
  let(:images) { instance_double 'ImageSet' }

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
    allow(PhotoFS::FS::FileMonitor).to receive(:new).and_return(file_monitor)
    allow(PhotoFS::Data::ImageSet).to receive(:new).and_return(images)
  end

  describe :matcher do
    it { expect(klass.match? ['import', '.']).to be true }
    it { expect(klass.match? ['import', './some/file/']).to be true }
    it { expect(klass.match? ['import', './some/file']).to be true }
    it { expect(klass.match? ['import', 'some/file']).to be true }
    it { expect(klass.match? ['import', '../some/file']).to be true }
    it { expect(klass.match? ['import', '../some/file\ spaces']).to be true }

    it { expect(klass.match? ['important', 'file']).to be false }
    it { expect(klass.match? ['important']).to be false }
    it { expect(klass.match? ['import']).to be false }
    it { expect(klass.match? ['something', 'else', 'entirely']).to be false }
  end

  describe :modify_datastore do
    before(:example) do
      allow(command).to receive(:puts) # swallow
      allow(images).to receive(:import).and_return([])
    end

    subject { command.modify_datastore }

    it 'should send paths from file monitor to image set' do
      expect(images).to receive(:import).with(file_monitor.paths)

      subject
    end

    context 'when images are imported' do
      before(:example) do
        allow(images).to receive(:import).and_return([double('an image', :path => 'some-path.jpg')])
      end

      it { should be true }
    end

    context 'when images are not imported' do
      before(:example) do
        allow(images).to receive(:import).and_return([])
      end

      it { should be false }
    end
  end

  describe :validate do
    before(:example) do
      allow(command).to receive(:valid_path).with(path).and_return(valid_path)
    end

    subject { command.validate }

    it { should eq(valid_path) }
  end
end
