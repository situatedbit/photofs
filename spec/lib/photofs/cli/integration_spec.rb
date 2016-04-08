require 'photofs/cli'
require 'photofs/cli/tag_command'
require 'photofs/data/synchronize'
require 'photofs/fs/test'

describe 'cli integration' do
  let(:cli_class) { PhotoFS::CLI }

  describe :tag do
    let(:command_class) { PhotoFS::CLI::TagCommand }
    let(:tag_class) { PhotoFS::Data::Tag }

    let(:image_path) { '/photos/src/some-file.jpg' }
    let(:argv) { ['tag', 'some-tag', image_path] }
    let(:file_system) { PhotoFS::FS::Test.new( { :files => [image_path, '/photofs/some-other-file.jpg'] } ) }

    before(:example) do
      allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
      allow(PhotoFS::FS).to receive(:data_path).and_return('/photos')
      allow_any_instance_of(command_class).to receive(:initialize_database)
      allow_any_instance_of(command_class).to receive(:set_data_path)
      allow(PhotoFS::Data::Synchronize).to receive(:read_write_lock).and_return(PhotoFS::Data::Synchronize::TestLock.new)

      create :image, :image_file => build(:file, :path => image_path)
    end

    it 'should create a tag' do
      cli_class.execute argv

      expect(tag_class.find_by(:name => 'some-tag')).to be_an_instance_of(tag_class)
    end

    it 'should tag the file with the tag' do
      cli_class.execute argv

      expect(tag_class.find_by(:name => 'some-tag').images.first.image_file.path).to eq(image_path)
    end

    context 'when the image is not in the library' do
      let(:argv) { ['tag', 'some-tag', '/photofs/some-other-file.jpg'] }

      it 'should throw an error' do
        expect { cli_class.execute argv }.to output(/is not a registered image/).to_stdout
      end
    end
  end # :tag
end
