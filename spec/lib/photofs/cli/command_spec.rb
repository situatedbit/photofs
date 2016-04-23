require 'photofs/cli/command'
require 'photofs/fs/test'

describe PhotoFS::CLI::Command do
  let(:command) { PhotoFS::CLI::Command.new [] }
  let(:file_system) { PhotoFS::FS::Test.new }

  before(:example) do
    allow(command).to receive(:file_system).and_return(file_system)
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
