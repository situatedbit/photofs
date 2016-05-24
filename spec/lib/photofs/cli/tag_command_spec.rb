require 'photofs/cli/command'
require 'photofs/cli/tag_command'
require 'photofs/core/tag'
require 'photofs/fs/test'

describe PhotoFS::CLI::TagCommand do
  let(:klass) { PhotoFS::CLI::TagCommand }
  let(:tag_arg) { 'good' }
  let(:image_arg) { '/a/b/c/image.jpg' }
  let(:image_path) { image_arg }
  let(:command) { PhotoFS::CLI::TagCommand.new(['tag', tag_arg, image_arg]) }

  let(:file_system) { PhotoFS::FS::Test.new( { :files => [image_arg] } )}

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)

    allow(command).to receive(:initialize_datastore) # swallow
  end

  describe :matcher do
    it { expect(klass.match? ['tag', 'a-tag', '/some/file/somewhere']).to be true }
    it { expect(klass.match? ['tag', '1324', './some/file/somewhere.jpg']).to be true }
    it { expect(klass.match? ['tag', '1324', './some/file/somewhere.jpg', './some/file/yet another.jpg']).to be true }
    it { expect(klass.match? ['tag', '1324,good', './some/file/somewhere.jpg', './some/file/yet another.jpg']).to be true }
    it { expect(klass.match? ['tag', '1324, good', './some/file/somewhere.jpg', './some/file/yet another.jpg']).to be true }
    it { expect(klass.match? ['another', 'tag', 'file']).to be false }
  end

  describe :modify_datastore do
    let(:tag) { instance_double('PhotoFS::Core::Tag', :add => nil) }
    let(:image) { instance_double('PhotoFS::Core::Image') }
    let(:valid_path) { 'a valid path' }

    before(:example) do
      command.instance_variable_set(:@real_image_paths, [image_path])
    end

    context 'when the tag exists' do
      before(:example) do
        allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with(tag_arg).and_return(tag)
        allow(command.instance_variable_get(:@images)).to receive(:find_by_paths).with([image_path]).and_return({image_path => image})
      end

      it 'should tag the image' do
        expect(tag).to receive(:add).with(image)

        command.modify_datastore
      end

      it 'should be true' do
        expect(command.modify_datastore).to be true
      end
    end

    context 'when the tag does not exist' do
      before(:example) do
        allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with(tag_arg).and_return(nil)
        allow(command.instance_variable_get(:@images)).to receive(:find_by_paths).with([image_path]).and_return({image_path => image})
        allow(command.instance_variable_get(:@tags)).to receive(:add?).and_return(tag)
      end

      it 'should create the tag' do
        expect(command.instance_variable_get(:@tags)).to receive(:add?).with(an_instance_of(PhotoFS::Core::Tag))

        command.modify_datastore
      end

      it 'should tag the image' do
        expect(tag).to receive(:add).with(image)

        command.modify_datastore
      end

      it 'should be true' do
        expect(command.modify_datastore).to be true
      end
    end

    context 'when there are multiple tags' do
      let(:tag1) { instance_double('PhotoFS::Core::Tag', :add => nil) }
      let(:tag2) { instance_double('PhotoFS::Core::Tag', :add => nil) }

      let(:tag_arg) { 'good, bad' }

      before(:example) do
        allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with('good').and_return(tag1)
        allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with('bad').and_return(tag2)

        allow(command.instance_variable_get(:@images)).to receive(:find_by_paths).with([image_path]).and_return({image_path => image})
      end

      it 'should tag the image twice' do
        expect(tag1).to receive(:add).with(image)
        expect(tag2).to receive(:add).with(image)

        command.modify_datastore
      end
    end

    context 'when the image is not in the repository' do
      before(:example) do
        allow(command.instance_variable_get(:@images)).to receive(:find_by_paths).with([image_path]).and_return({image_path => nil})
      end

      it 'should throw an error' do
        expect { command.modify_datastore }.to raise_error(PhotoFS::CLI::Command::CommandException)
      end
    end
  end # :modify_datastore

  describe :validate do
    before(:example) do
      allow(command).to receive(:valid_path).with(image_arg).and_return(image_path)
    end

    subject { command.validate }

    it { should eq([image_path]) }
  end
end
