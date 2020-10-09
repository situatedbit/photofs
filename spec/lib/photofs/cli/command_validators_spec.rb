require 'photofs/cli/command_validators'

describe PhotoFS::CLI::CommandValidators do
  class PhotoFS::CLI::CommandValidators::TestCommand
    include PhotoFS::CLI::CommandValidators
  end

  let(:command) { PhotoFS::CLI::CommandValidators::TestCommand.new }

  describe :valid_path do
    let(:path) { 'a path' }
    let(:real_path) { 'the real path' }
    let(:file_system) { double('FileSystem') }

    before(:example) do
      allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
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
