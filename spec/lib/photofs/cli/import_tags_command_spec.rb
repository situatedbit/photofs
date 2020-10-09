require 'photofs/cli/command_validators'
require 'photofs/cli/import_tags_command'
require 'photofs/cli/tag_json_parser'
require 'photofs/core/tag'
require 'photofs/core/tag_set'
require 'photofs/data/tag_set'
require 'photofs/fs/test'

describe PhotoFS::CLI::ImportTagsCommand do
  let(:path) { 'a/b/c/' }
  let(:valid_path) { '/a/b/c' }
  let(:command) { PhotoFS::CLI::ImportTagsCommand.new(['import', 'tags', path]) }
  let(:file_system) { PhotoFS::FS::Test.new( { files: [] } )}
  let(:tags) { instance_double 'TagSet' }

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
    allow(PhotoFS::FS).to receive(:images_path).and_return('/arbitrary/root/path')
    allow(PhotoFS::Data::TagSet).to receive(:new).and_return(tags)
  end

  describe :datastore_start_path do
    let(:working_dir) { '/my/working/directory' }

    before(:example) do
      allow(file_system).to receive(:pwd).and_return(working_dir)
    end

    it { expect(command.datastore_start_path).to eq(working_dir) }
  end

  describe :matcher do
    let(:command) { PhotoFS::CLI::ImportTagsCommand }

    it { expect(command.match? ['import', 'tags', './some/file/']).to be true }
    it { expect(command.match? ['import', 'tags', './some/file']).to be true }
    it { expect(command.match? ['import', 'tags', 'some/file']).to be true }
    it { expect(command.match? ['import', 'tags', '../some/file']).to be true }
    it { expect(command.match? ['import', 'tags', '../some/file\ spaces']).to be true }

    it { expect(command.match? ['import']).to be false }
    it { expect(command.match? ['import', 'tags']).to be false }
    it { expect(command.match? ['something', 'else', 'entirely']).to be false }
  end

  describe :modify_datastore do
    before(:example) do
      allow(tags).to receive(:save!)
      allow(command).to receive(:tag_images).and_return(nil)

      command.instance_variable_set(:@tags_to_import, tags_to_import)
    end

    context 'when there are tags to import' do
      let(:tags_to_import) { [PhotoFS::Core::Tag.new('tree'), PhotoFS::Core::Tag.new('bark')] }

      it 'should call tag_images for each tag in the set' do
        expect(command).to receive(:tag_images).exactly(2).times

        command.modify_datastore
      end

      it 'should call save on the tags set' do
        expect(tags).to receive(:save!)

        command.modify_datastore
      end

      it 'should be true' do
        expect(command.modify_datastore).to be true
      end
    end

    context 'when there are no tags to import' do
      let(:tags_to_import) { [] }

      it 'should be false' do
        expect(command.modify_datastore).to be false
      end
    end
  end

  describe :validate do
    let(:validation_exception) { PhotoFS::CLI::CommandValidators::CommandValidationException }

    it 'should fail if the JSON file does not exist' do
      allow(file_system).to receive(:exist?).and_return(false)

      expect { command.validate }.to raise_error(validation_exception)
    end

    it 'should fail if the JSON file is not a file' do
      allow(file_system).to receive(:directory?).and_return(true)

      expect { command.validate }.to raise_error(validation_exception)
    end

    context 'the JSON file exists' do
      let(:parser) { instance_double(PhotoFS::CLI::TagJsonParser) }

      before(:example) do
        allow(file_system).to receive(:exist?).and_return(true)
        allow(file_system).to receive(:directory?).and_return(false)

        command.instance_variable_set(:@parser, parser)
      end

      context 'but it does not parse correctly' do
        it 'should fail' do
          allow(parser).to receive(:parse).and_raise(PhotoFS::CLI::TagJsonParser::ParseException)

          expect { command.validate }.to raise_error(PhotoFS::CLI::TagJsonParser::ParseException)
        end
      end

      context 'and parses correctly' do
        it 'should set tags to import instance variable' do
          allow(parser).to receive(:parse).and_return(PhotoFS::Core::TagSet.new)

          command.validate

          expect(command.instance_variable_get(:@tags_to_import)).to be_an_instance_of(PhotoFS::Core::TagSet)
        end
      end
    end
  end

end
