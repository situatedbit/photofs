require 'photofs/cli/import_command'
require 'photofs/data/image_set'
require 'photofs/fs/file_monitor'
require 'photofs/fs/test'

describe PhotoFS::CLI::ImportCommand, :type => :locking_behavior do
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
    it { expect(PhotoFS::CLI::ImportCommand.matcher).to match('import .') }
    it { expect(PhotoFS::CLI::ImportCommand.matcher).to match('import ./some/file/') }
    it { expect(PhotoFS::CLI::ImportCommand.matcher).to match('import ./some/file') }
    it { expect(PhotoFS::CLI::ImportCommand.matcher).to match('import some/file') }
    it { expect(PhotoFS::CLI::ImportCommand.matcher).to match('import ../some/file') }
    it { expect(PhotoFS::CLI::ImportCommand.matcher).to match('import ../some/file\ spaces') }
    it { expect(PhotoFS::CLI::ImportCommand.matcher).not_to match('import') }
    it { expect(PhotoFS::CLI::ImportCommand.matcher).not_to match('something else entirely') }
  end

  describe :execute do
    before(:example) do
      allow(command).to receive(:initialize_datastore) # swallow
      allow(command).to receive(:puts) # swallow

      allow(command).to receive(:valid_path).with(path).and_return(valid_path)
      allow(images).to receive(:import_paths)
    end

    it 'should initialize datastore with a valid path' do
      expect(command).to receive(:valid_path).with(path)
      expect(command).to receive(:initialize_datastore).with(valid_path)

      command.execute
    end

    it 'should send paths from file monitor to image set' do
      expect(images).to receive(:import_paths).with(file_monitor.paths)

      command.execute
    end
  end # :execute
end
