require 'photofs/cli'
require 'photofs/cli/tag_command'
require 'photofs/fs/test'

describe 'cli integration', :type => :locking_behavior do
  let(:cli) { PhotoFS::CLI }
  let(:file_system) { PhotoFS::FS::Test.new }

  before(:example) do
    allow_any_instance_of(PhotoFS::CLI::Command).to receive(:initialize_datastore)
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
  end

  describe :tag do
    let(:tag_class) { PhotoFS::Data::Tag }

    let(:image_path) { '/photos/src/some-file.jpg' }
    let(:image2_path) { '/photos/src/another-file.jpg' }
    let(:argv) { ['tag', 'some-tag', image_path] }
    let(:file_system) { PhotoFS::FS::Test.new( { :files => [image_path, image2_path, '/photofs/some-other-file.jpg'] } ) }

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
        expect { cli.execute argv }.to output(/not imported/).to_stdout
      end
    end

    context 'when several images are included' do
      let(:images) { [image_path, image2_path] }
      let(:argv) { ['tag', 'good'] + images }

      before(:example) do
        create :image, :image_file => build(:file, :path => image2_path)
      end

      it 'should apply tags to several images at once' do
        cli.execute argv

        expect(tag_class.find_by(:name => 'good').images.map { |i| i.image_file.path }).to contain_exactly(*images)
      end
    end

    context 'when several tags and images are included' do
      let(:images) { [image_path, image2_path] }
      let(:argv) { ['tag', 'good bad'] + images }

      before(:example) do
        create :image, :image_file => build(:file, :path => image2_path)
      end

      it 'should apply tags to several images at once' do
        cli.execute argv
        ['good', 'bad'].each do |tag|
          expect(tag_class.find_by(:name => tag).images.map { |i| i.image_file.path }).to contain_exactly(*images)
        end
      end
    end
  end # :tag

  describe :tag_rename do
    it 'should raise error when tag does not exist' do
      expect { cli.execute ['rename', 'tag', 'not-exist', 'will-exist'] }.to output(/tag does not exist/).to_stdout
    end

    context 'when the tag exists' do
      let(:from_tag_name) { 'existing-tag' }
      let(:to_tag_name) { 'new-tag' }

      let!(:images) { create_images ['/a/b/c/1.jpg', '/a/b/c/2.jpg'] }
      let!(:from_tag) { create :tag, :name => from_tag_name }

      let(:argv) { ['rename', 'tag', from_tag_name, to_tag_name] }

      before(:example) do
        from_tag.images = images
        from_tag.save

        cli.execute argv
      end

      it 'should create a new tag' do
        expect(PhotoFS::Data::Tag.find_by_name to_tag_name).to be_instance_of(PhotoFS::Data::Tag)
      end

      it 'should move all images under the new tag' do
        expect(PhotoFS::Data::Tag.find_by_name(to_tag_name).images).to contain_exactly(*images)
      end

      it 'should remove the old tag' do
        expect(PhotoFS::Data::Tag.find_by_name from_tag_name).to be_nil
      end
    end
  end # #tag_rename

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
