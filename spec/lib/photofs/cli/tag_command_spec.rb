require 'photofs/cli/tag_command'
require 'photofs/core/tag'
require 'photofs/fs/test'

describe PhotoFS::CLI::TagCommand do
  let(:tag_arg) { 'good' }
  let(:image_arg) { '/a/b/c/image.jpg' }
  let(:image_path) { image_arg }
  let(:tag_command) { PhotoFS::CLI::TagCommand.new(['tag', tag_arg, image_arg]) }

  let(:file_system) { PhotoFS::FS::Test.new( { :files => [image_arg] } )}

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)

    allow(tag_command).to receive(:set_data_path) # swallow
    allow(tag_command).to receive(:initialize_database) # swallow
    allow(tag_command).to receive(:increment_database_write_counter) # swallow
    allow(tag_command).to receive(:data_lock) { |&block| block.call }
  end

  describe :matcher do
    it { PhotoFS::CLI::TagCommand.matcher.should match('tag a-tag /some/file/somewhere') }
    it { PhotoFS::CLI::TagCommand.matcher.should match('tag 1324 ./some/file/somewhere.jpg') }
    it { PhotoFS::CLI::TagCommand.matcher.should_not match('another tag file') }
  end

  context 'when the image argument is not a real file' do
    before(:example) do
      allow(file_system).to receive(:exist?).and_return(false)
    end

    it 'should throw an error' do
      expect { PhotoFS::CLI::TagCommand.new(['tag', 'good', 'image.jpg']) }.to raise_error(Errno::ENOENT)
    end
  end

  describe :execute do
    let(:tag) { instance_double('PhotoFS::Core::Tag', :add => nil) }
    let(:image) { instance_double('PhotoFS::Core::Image') }

    context 'when the tag exists' do
      before(:example) do
        allow(tag_command.instance_variable_get(:@tags)).to receive(:find_by_name).with(tag_arg).and_return(tag)
        allow(tag_command.instance_variable_get(:@images)).to receive(:find_by_path).with(image_path).and_return(image)
      end

      it 'should tag the image' do
        expect(tag).to receive(:add).with(image)

        tag_command.execute
      end
    end

    context 'when the tag does not exist' do
      before(:example) do
        allow(tag_command.instance_variable_get(:@tags)).to receive(:find_by_name).with(tag_arg).and_return(nil)
        allow(tag_command.instance_variable_get(:@images)).to receive(:find_by_path).with(image_path).and_return(image)
        allow(tag_command.instance_variable_get(:@tags)).to receive(:add?).and_return(tag)
      end

      it 'should create the tag' do
        expect(tag_command.instance_variable_get(:@tags)).to receive(:add?).with(an_instance_of(PhotoFS::Core::Tag))

        tag_command.execute
      end

      it 'should tag the image' do
        expect(tag).to receive(:add).with(image)

        tag_command.execute
      end
    end

    context 'when the image is not in the repository' do
      before(:example) do
        allow(tag_command.instance_variable_get(:@images)).to receive(:find_by_path).with(image_path).and_return(nil)
        allow(PhotoFS::FS).to receive(:data_path).and_return('a path')
      end

      it 'should throw an error' do
        expect { tag_command.execute }.to raise_error(PhotoFS::CLI::Command::CommandException)
      end
    end
  end # :execute
end
