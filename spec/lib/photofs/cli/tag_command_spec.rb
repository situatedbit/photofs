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
    it { expect(klass.match? ['tag', '1324 good', './some/file/somewhere.jpg', './some/file/yet another.jpg']).to be true }
    it { expect(klass.match? ['another', 'tag', 'file']).to be false }
  end

  describe :modify_datastore do
    let(:tag_set) { command.instance_variable_get(:@tags) }
    let(:image_set) { command.instance_variable_get(:@images) }
    let(:image) { instance_double('PhotoFS::Core::Image') }
    let(:image_paths) { double('Array') }
    let(:valid_images) { [double('Image', :path => image_path)] }

    subject { command.modify_datastore }

    before(:example) do
      command.instance_variable_set(:@real_image_paths, image_paths)

      allow(command).to receive(:valid_images_from_paths).with(image_set, image_paths).and_return(valid_images)
      allow(command).to receive(:tag_images).and_return(nil)
    end

    it 'should tag the image' do
      expect(command).to receive(:tag_images).with(tag_set, tag_arg, valid_images)

      subject
    end

    it 'should output the images that were tagged' do
      subject

      expect(command.output).to match(/#{tag_arg} ∈ #{image_arg}/)
    end

    it { expect(subject).to be true }

    context 'when there are multiple tags' do
      let(:tag1) { 'good' }
      let(:tag2) { 'bad' }
      let(:tag_arg) { [tag1, tag2].join ' ' }

      after(:example) do
        subject
      end

      it { expect(command).to receive(:tag_images).with(tag_set, tag1, valid_images) }
      it { expect(command).to receive(:tag_images).with(tag_set, tag2, valid_images) }
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
      allow(command).to receive(:valid_path).with(image_arg).and_return(image_path)
    end

    subject { command.validate }

    it { should eq([image_path]) }
  end
end
