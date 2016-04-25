require 'photofs/cli/command'
require 'photofs/data/synchronize'
require 'photofs/fs/test'

describe PhotoFS::CLI::Command, :type => :locking_behavior do
  let(:command) { PhotoFS::CLI::Command.new [] }
  let(:file_system) { PhotoFS::FS::Test.new }

  before(:example) do
    allow(command).to receive(:file_system).and_return(file_system)
    allow(command).to receive(:initialize_datastore)
  end

  describe :datastore_start_path do
    it 'needs to be implemented by subclass' do
      expect { command.datastore_start_path }.to raise_error(NotImplementedError)
    end
  end

  describe :execute do
    before(:example) do
      allow(command).to receive(:datastore_start_path).and_return('/path')
      allow(command).to receive(:modify_datastore).and_return(true)
    end

    after(:example) do
      command.execute
    end

    it 'will call validate' do
      expect(command).to receive(:validate)
    end

    it 'will initialize datastore' do
      expect(command).to receive(:initialize_datastore).with(command.datastore_start_path)
    end
  end

  describe :modify_datastore do
    it 'must be implemented by subclass' do
      expect { command.modify_datastore }.to raise_error(NotImplementedError)
    end
  end

  describe :valid_path do
    let(:path) { 'a path' }
    let(:real_path) { 'the real path' }

    before(:example) do
      allow(file_system).to receive(:realpath).with(path).and_return(real_path)
      allow(file_system).to receive(:exist?).and_return(true)
    end

    it 'will raise an error if the file does not exist' do
      allow(file_system).to receive(:exist?).with(path).and_raise(Errno::ENOENT)

      expect { command.valid_path path }.to raise_error(Errno::ENOENT)
    end

    it 'will return the result of realpath' do
      expect(command.valid_path path).to eq(real_path)
    end
  end
end
