require 'photofs/cli'
require 'photofs/cli/tag_command'
require 'photofs/fs/test'

describe 'cli integration', :type => :locking_behavior do
  def create_images(paths)
    paths.each { |path| create(:image, :image_file => build(:file, :path => path)) }
  end

  let(:cli) { PhotoFS::CLI }

  before(:example) do
    allow_any_instance_of(PhotoFS::CLI::Command).to receive(:initialize_datastore)
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
  end

  describe :tag do
    let(:tag_class) { PhotoFS::Data::Tag }

    let(:image_path) { '/photos/src/some-file.jpg' }
    let(:argv) { ['tag', 'some-tag', image_path] }
    let(:file_system) { PhotoFS::FS::Test.new( { :files => [image_path, '/photofs/some-other-file.jpg'] } ) }

    before(:example) do
      allow(PhotoFS::FS).to receive(:data_path).and_return('/photos')

      create :image, :image_file => build(:file, :path => image_path)
    end

    it 'should create a tag' do
      cli.execute argv

      expect(tag_class.find_by(:name => 'some-tag')).to be_an_instance_of(tag_class)
    end

    it 'should tag the file with the tag' do
      cli.execute argv

      expect(tag_class.find_by(:name => 'some-tag').images.first.image_file.path).to eq(image_path)
    end

    context 'when the image is not in the library' do
      let(:argv) { ['tag', 'some-tag', '/photofs/some-other-file.jpg'] }

      it 'should throw an error' do
        expect { cli.execute argv }.to output(/is not a registered image/).to_stdout
      end
    end
  end # :tag

  describe :import do
    let(:top_path) { '/a/b/c' }
    let(:path1) { '/a/b/c/1.jpg' }
    let(:path2) { '/a/b/c/2.jpg' }
    let(:path3) { '/a/b/c/3.jpg' }
    let(:files) { [path1, path2, path3] }

    let(:file_system) { PhotoFS::FS::Test.new( { :files => files } ) }

    before(:example) do
      create_images [path1, path2]

      allow_any_instance_of(PhotoFS::CLI::ImportCommand).to receive(:puts) # swallow output

      allow(PhotoFS::FS::FileMonitor).to receive(:new).with(top_path).and_return(instance_double('FileMonitor', :paths => files))
    end

    it 'should add images under the path that are not in the database' do
      cli.execute ['import', top_path]

      expect(PhotoFS::Data::Image.find_by_image_file_paths [path3]).to contain_exactly(an_instance_of PhotoFS::Data::Image)
    end
  end # :import
end
