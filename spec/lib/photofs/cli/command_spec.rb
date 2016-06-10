require 'photofs/cli/command'
require 'photofs/data/synchronize'
require 'photofs/fs/test'

describe PhotoFS::CLI::Command, :type => :locking_behavior do
  let(:command) { PhotoFS::CLI::Command.new [] }

  before(:example) do
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
end
