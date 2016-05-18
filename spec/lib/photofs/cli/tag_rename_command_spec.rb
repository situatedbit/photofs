require 'photofs/cli/tag_rename_command'
require 'photofs/data/image_set'
require 'photofs/fs/file_monitor'
require 'photofs/fs/test'

describe PhotoFS::CLI::TagRenameCommand do
  let(:klass) { PhotoFS::CLI::TagRenameCommand }
  let(:from) { 'old-tag' }
  let(:to) { 'new-tag' }
  let(:command) { PhotoFS::CLI::TagRenameCommand.new(['rename', 'tag', from, to]) }
  let(:tags) { instance_double 'TagSet' }
  let(:from_tag) { instance_double 'Tag' }

  before(:example) do
    allow(PhotoFS::Data::TagSet).to receive(:new).and_return(tags)
    allow(tags).to receive(:rename)
    allow(tags).to receive(:save!)
  end

  describe :matcher do
    it { expect(klass.match? ['rename', 'tag', 'some-tag', 'another-tag']).to be true }
    it { expect(klass.match? ['rename', 'tag', 'some', 'tag', 'another', 'tag']).to be false }
    it { expect(klass.match? ['something', 'else', 'entirely']).to be false }
  end

  describe :datastore_start_path do
    before(:example) do
      allow(Dir).to receive(:getwd).and_return('/this/directory')
    end

    it 'should return current directory' do
      expect(command.datastore_start_path).to eq '/this/directory'
    end
  end

  describe :modify_datastore do
    context 'when from tag exists' do
      before(:example) do
        allow(tags).to receive(:find_by_name).with(from).and_return(from_tag)
        allow(tags).to receive(:find_by_name).with(to).and_return(nil)
      end

      it 'should be true' do
        expect(command.modify_datastore).to be true
      end

      it 'should call rename on tag set' do
        expect(tags).to receive(:rename).with(from_tag, an_instance_of(PhotoFS::Core::Tag))

        command.modify_datastore
      end
    end

    context 'when from tag does not exist' do
      before(:example) do
        allow(tags).to receive(:find_by_name).with(from).and_return(nil)
      end

      it 'should raise error' do
        expect { command.modify_datastore }.to raise_error(PhotoFS::CLI::Command::CommandException)
      end
    end

    context 'when to tag already exists' do
      before(:example) do
        allow(tags).to receive(:find_by_name).with(from).and_return(from_tag)
        allow(tags).to receive(:find_by_name).with(to).and_return(instance_double('Tag'))
      end

      it 'should raise error' do
        expect { command.modify_datastore }.to raise_error(PhotoFS::CLI::Command::CommandException)
      end
    end
  end # :modify_datastore
end
