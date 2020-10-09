require 'photofs/cli/init_command'
require 'photofs/fs/test'

describe PhotoFS::CLI::InitCommand do
  let(:path) { '/a/b/c' }
  let(:photofs_path) { [path, '.photofs'].join('/') }
  let(:command) { PhotoFS::CLI::InitCommand.new(['init', path]) }
  let(:file_system) { PhotoFS::FS::Test.new( { dirs: [ photofs_path ] } )}

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
  end

  describe :datastore_start_path do
    it 'should be the path argument' do
       expect(command.datastore_start_path).to eq(path)
    end
  end

  describe :matcher do
    let(:command) { PhotoFS::CLI::InitCommand }

    it { expect(command.match? ['init', './some/path/']).to be true }
    it { expect(command.match? ['init', './some/path']).to be true }
    it { expect(command.match? ['init', 'some/file']).to be true }
    it { expect(command.match? ['init', '../some/path']).to be true }
    it { expect(command.match? ['init', '../some/path\ spaces']).to be true }

    it { expect(command.match? ['init']).to be false }
    it { expect(command.match? ['something', 'else', 'entirely']).to be false }
  end

  describe :initialize_datastore do
    let(:connection) { instance_double('Connection', create_schema: true)}

    before(:example) do
      allow(PhotoFS::Data::Database::Connection).to receive(:new).and_return(connection)
      allow(connection).to receive(:connect).and_return(connection)
    end

    it 'should call create_schema on the database connection' do
      expect(connection).to receive(:create_schema)

      command.initialize_datastore path
    end
  end

  describe :modify_datastore do
    it { expect(command.modify_datastore).to be true }
  end

  describe :validate do
    before(:example) do
      allow(command).to receive(:valid_path).with(path).and_return(path)
    end

    it 'validate path' do
      expect(command).to receive(:valid_path).with(path)

      command.validate
    end
  end
end
