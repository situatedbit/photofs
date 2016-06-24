require 'photofs/cli/retag_command'
require 'photofs/fs/test'

describe PhotoFS::CLI::RetagCommand do
  let(:klass) { PhotoFS::CLI::RetagCommand }
  let(:old_tag_name) { 'good' }
  let(:new_tag_name) { 'bad' }
  let(:old_tag_arg) { old_tag_name }
  let(:new_tag_arg) { new_tag_name }
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
    it { expect(klass.match? ['retag', 'old tags', 'new tags', './some/file/somewhere.jpg', 'another-file.jpg']).to be true }
    it { expect(klass.match? ['retag', 'old', './some/file/somewhere.jpg']).to be false }
    it { expect(klass.match? ['retag', '1324 good', './some/file/somewhere.jpg']).to be false }
    it { expect(klass.match? ['another', 'tag', 'file']).to be false }
  end

  describe :modify_datastore do
    let(:tag_set) { command.instance_variable_get(:@tags) }
    let(:image_set) { command.instance_variable_get(:@images) }
    let(:image) { instance_double('PhotoFS::Core::Image') }
    let(:image_paths) { double('Array') }
    let(:valid_images) { double('Array') }

    subject { command.modify_datastore }

    before(:example) do
      command.instance_variable_set(:@real_image_paths, image_paths)

      allow(command).to receive(:valid_images_from_paths).with(image_set, image_paths).and_return(valid_images)

      allow(command).to receive(:tag_images).and_return(nil)
      allow(command).to receive(:untag_images).and_return(nil)

      allow(tag_set).to receive(:save!)
      allow(image_set).to receive(:save!)
    end

    it 'should tag the image' do
      expect(command).to receive(:tag_images).with(tag_set, new_tag_arg, valid_images)

      subject
    end

    it { expect(subject).to be true }

    context 'when there are multiple new tags' do
      let(:tag1) { 'good' }
      let(:tag2) { 'bad' }
      let(:new_tag_arg) { [tag1, tag2].join ' ' }

      after(:example) do
        subject
      end

      it { expect(command).to receive(:tag_images).with(tag_set, tag1, valid_images) }
      it { expect(command).to receive(:tag_images).with(tag_set, tag2, valid_images) }
    end

    context 'when there are multiple old tags' do
      let(:tag1) { 'good' }
      let(:tag2) { 'bad' }
      let(:old_tag_arg) { [tag1, tag2].join ' ' }

      after(:example) do
        subject
      end

      it { expect(command).to receive(:untag_images).with(tag_set, tag1, valid_images) }
      it { expect(command).to receive(:untag_images).with(tag_set, tag2, valid_images) }
    end

    context 'when the image is not in the repository' do
      before(:example) do
        allow(command).to receive(:valid_images_from_paths).and_raise(PhotoFS::CLI::Command::CommandException)
      end

      it 'should throw an error' do
        expect { subject }.to raise_error(PhotoFS::CLI::Command::CommandException)
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
