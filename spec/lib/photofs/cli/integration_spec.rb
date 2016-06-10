require 'photofs/cli'
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

      create_image image_path
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
        create_image image2_path
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

  describe :prune do
    let(:path1) { '/a/b/c/1.jpg' }
    let(:path2) { '/a/b/c/2.jpg' }
    let(:path3) { '/a/b/c/3.jpg' }
    let(:path4) { '/a/x/y/z.jpg' }
    let(:files) { [path1, path2] }
    let(:images) { [path1, path2, path3, path4] }
    let(:remaining_images) { PhotoFS::Data::Image.all.map { |i| i.path } }

    let(:file_system) { PhotoFS::FS::Test.new( { :files => files } ) }

    before(:each) do
      create_images images

      allow_any_instance_of(PhotoFS::CLI::PruneCommand).to receive(:puts) # swallow output
    end

    it 'should remove images that are missing from the file system' do
      cli.execute ['prune', '/a/b/c']

      expect(remaining_images).to contain_exactly(path1, path2, path4)
    end

    it 'should descend the directory tree to prune' do
      cli.execute ['prune', '/a']

      expect(remaining_images).to contain_exactly(*files)
    end

    it 'should prune from the path above the file, if given' do
      cli.execute ['prune', '/a/b/c/1.jpg']

      expect(remaining_images).to contain_exactly(path1, path2, path4)
    end
  end # :prune

  describe :retag do
    let(:path1) { '/a/b/c/1.jpg' }
    let(:path2) { '/a/b/c/2.jpg' }
    let(:unimported_file) { '/a/b/c/not-imported.jpg' }
    let(:image_paths) { [path1, path2] }
    let(:image_records) { create_images image_paths }

    let(:file_system) { PhotoFS::FS::Test.new( { :files => (image_paths + [unimported_file]) } ) }

    let(:good_tag_record) { create :tag, :name => 'good' }
    let(:bad_tag_record) { create :tag, :name => 'bad' }
    let(:tag_records) { [good_tag_record, bad_tag_record] }

    context 'when all images exist' do
      before(:example) do
        allow_any_instance_of(PhotoFS::CLI::RetagCommand).to receive(:puts) # swallow output

        image_records
      end

      context 'old and new tags exist' do
        before(:each) do
          tag_records

          good_tag_record.images = image_records

          good_tag_record.save
        end

        it 'should remove any applications of old tag to images' do
          cli.execute ['retag', 'good', 'bad', '/a/b/c/1.jpg', '/a/b/c/2.jpg']

          expect(PhotoFS::Data::Tag.from_tag(good_tag_record.to_simple).images).to be_empty
        end

        it 'should apply new tag to images' do
          cli.execute ['retag', 'good', 'bad', '/a/b/c/1.jpg', '/a/b/c/2.jpg']

          expect(PhotoFS::Data::Tag.from_tag(bad_tag_record.to_simple).images).to contain_exactly(*image_records)
        end
      end

      context 'when new tag does not yet exist' do
        before(:each) do
          good_tag_record
        end

        it 'should create it' do
          cli.execute ['retag', 'good', 'bad', '/a/b/c/1.jpg', '/a/b/c/2.jpg']

          expect(PhotoFS::Data::Tag.from_tag(double('Tag', :name => 'bad'))).to be_an_instance_of(PhotoFS::Data::Tag)
        end
      end
    end

    context 'if one of the images is not yet imported' do
      it { expect { cli.execute ['retag', 'good', 'bad', '/a/b/c/1.jpg', unimported_file] }.to output(/not imported/).to_stdout }
    end
  end # :retag
end
