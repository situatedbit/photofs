require 'photofs/cli/retag_command'
require 'photofs/fs/test'

describe PhotoFS::CLI::RetagCommand do
  let(:klass) { PhotoFS::CLI::RetagCommand }
  let(:old_tag_arg) { 'good' }
  let(:new_tag_arg) { 'bad' }
  let(:path_arg) { '/a/b/c/1.jpg' }
  let(:command) { klass.new(['retag', old_tag_arg, new_tag_arg, path_arg]) }

  let(:file_system) { PhotoFS::FS::Test.new( { :files => [path_arg] } )}

  before(:example) do
   allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)

    allow(command).to receive(:initialize_datastore) # swallow
  end

  describe :matcher do
    it { expect(klass.match? ['retag', 'old-tag', 'new-tag', '/some/file/somewhere']).to be true }
    it { expect(klass.match? ['retag', 'old-tag', 'new-tag', './some/file/somewhere.jpg', 'another-file.jpg']).to be true }
    it { expect(klass.match? ['retag', 'old', './some/file/somewhere.jpg']).to be false }
    it { expect(klass.match? ['retag', '1324 good', './some/file/somewhere.jpg']).to be false }
    it { expect(klass.match? ['another', 'tag', 'file']).to be false }
  end

  describe :modify_datastore do
    let(:new_tag) { instance_double('PhotoFS::Core::Tag', :add => nil) }
    let(:old_tag) { instance_double('PhotoFS::Core::Tag', :remove => nil) }
    let(:image) { double('Image', :path => path_arg) }

    before(:example) do
      command.instance_variable_set(:@real_image_paths, [path_arg])

      allow(command.instance_variable_get(:@images)).to receive(:find_by_paths).with([path_arg]).and_return({path_arg => image})
      allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with(old_tag_arg).and_return(old_tag)
      allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with(new_tag_arg).and_return(nil)

      allow(command.instance_variable_get(:@tags)).to receive(:save!)
      allow(command.instance_variable_get(:@images)).to receive(:save!)
    end

    it 'should untag images from old tag' do
      expect(old_tag).to receive(:remove).with([image])

      command.modify_datastore
    end

    context 'when the new_tag exists' do
      before(:example) do
        allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with(new_tag_arg).and_return(new_tag)
      end

      it 'should tag the image' do
        expect(new_tag).to receive(:add).with(image)

        command.modify_datastore
      end

      it 'should be true' do
        expect(command.modify_datastore).to be true
      end
    end

    context 'when the tag does not exist' do
      before(:example) do
        allow(command.instance_variable_get(:@tags)).to receive(:find_by_name).with(new_tag_arg).and_return(nil)
        allow(command.instance_variable_get(:@images)).to receive(:find_by_paths).with([path_arg]).and_return({path_arg => image})
        allow(command.instance_variable_get(:@tags)).to receive(:add?).and_return(new_tag)
      end

      it 'should create the tag' do
        expect(command.instance_variable_get(:@tags)).to receive(:add?).with(an_instance_of(PhotoFS::Core::Tag))

        command.modify_datastore
      end

      it 'should tag the image' do
        expect(new_tag).to receive(:add).with(image)

        command.modify_datastore
      end

      it 'should be true' do
        expect(command.modify_datastore).to be true
      end
    end

    context 'when an image is not in the repository' do
      before(:example) do
        allow(command.instance_variable_get(:@images)).to receive(:find_by_paths).with([path_arg]).and_return({path_arg => nil})
      end

      it 'should throw an error' do
        expect { command.modify_datastore }.to raise_error(PhotoFS::CLI::Command::CommandException)
      end
    end
  end # :modify_datastore

  describe :validate do
    before(:example) do
      allow(command).to receive(:valid_path).with(path_arg).and_return(path_arg)
    end

    subject { command.validate }

    it { should eq([path_arg]) }
  end
end
