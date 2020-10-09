require 'photofs/cli'
require 'photofs/fs/test'
require 'json'

describe 'cli integration', :type => :locking_behavior do
  let(:cli) { PhotoFS::CLI }
  let(:file_system) { PhotoFS::FS::Test.new }
  let(:images_root) { '/home/usr/photos' }

  before do
    $stdout = StringIO.new # Suppress output!
  end

  after(:all) do
    $stdout = STDOUT
  end

  before(:example) do
    allow_any_instance_of(PhotoFS::CLI::Command).to receive(:initialize_datastore)
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
    PhotoFS::FS.data_path_parent = images_root
  end

  describe :export_tags do
    context 'when the repository has no tags' do
      let(:argv) { ['export', 'tags' ]}

      context 'when the repository is empty' do
        it 'should produce a JSON file with no tags' do
          json = /{"tags":\[\]}/

          expect { cli.execute(argv) }.to output(json).to_stdout
        end
      end

      context 'when the repository has tags and images' do
        before(:example) do
          image_1, image_2 = create_images ['1.jpg', '2.jpg']

          tree_tag = create :tag, { name: 'tree' }
          create :tag_binding, { tag: tree_tag, image: image_1 }
          create :tag_binding, { tag: tree_tag, image: image_2 }

          bark_tag = create :tag, { name: 'bark' }
          create :tag_binding, { tag: bark_tag, image: image_1 }

          root_tag = create :tag, { name: 'root' }
        end

        it 'should product a JSON file with those tags and images' do
          # brittle, I know
          json = %Q[{"tags":[{"name":"tree","paths":["1.jpg","2.jpg"]},{"name":"bark","paths":["1.jpg"]},{"name":"root","paths":[]}]}\n]

          expect { cli.execute(argv) }.to output(json).to_stdout
        end
      end
    end

  end

  describe :tag do
    let(:tag_class) { PhotoFS::Data::Tag }

    let(:image_path) { 'src/some-file.jpg' }
    let(:image2_path) { 'src/another-file.jpg' }
    let(:files) { [image_path, image2_path, 'some-other-file.jpg'].map { |p| [images_root, p].join('/') } }
    let(:argv) { ['tag', 'some-tag', files[0]] }
    let(:file_system) { PhotoFS::FS::Test.new(files: files) }

    before(:example) do
      create_image image_path
    end

    it 'should create a tag' do
      cli.execute argv

      expect(tag_class.find_by(name: 'some-tag')).to be_an_instance_of(tag_class)
    end

    it 'should tag the file with the tag' do
      cli.execute argv

      expect(tag_class.find_by(name: 'some-tag').images.first.path).to eq(image_path)
    end

    context 'when the image is not in the library' do
      let(:argv) { ['tag', 'some-tag', '/home/usr/photos/some-other-file.jpg'] }

      it 'should throw an error' do
        expect { cli.execute argv }.to output(/not imported/).to_stdout
      end
    end

    context 'when several images are included' do
      let(:images) { [image_path, image2_path] }
      let(:files) { images.map { |p| [images_root, p].join('/') } }
      let(:argv) { ['tag', 'good'] + files }

      before(:example) do
        create_image image2_path
      end

      it 'should apply tags to several images at once' do
        cli.execute argv

        expect(tag_class.find_by(name: 'good').images.map { |i| i.path }).to contain_exactly(*images)
      end
    end

    context 'when several tags and images are included' do
      let(:images) { [image_path, image2_path] }
      let(:files) { images.map { |p| [images_root, p].join('/') } }
      let(:argv) { ['tag', 'good bad'] + files }

      before(:example) do
        create :image, path: image2_path
      end

      it 'should apply tags to several images at once' do
        cli.execute argv
        ['good', 'bad'].each do |tag|
          expect(tag_class.find_by(name: tag).images.map { |i| i.path }).to contain_exactly(*images)
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
      let!(:from_tag) { create :tag, name: from_tag_name }

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

  describe :import_image do
    let(:search_path) { [images_root, 'a'].join('/') }
    let(:path1) { 'a/b/c/1.jpg' }
    let(:path2) { 'a/b/c/2.jpg' }
    let(:path3) { 'a/b/c/3.jpg' }
    let(:paths) { [path1, path2, path3] }
    let(:files) { paths.map { |p| [images_root, p].join('/') } }
    let(:working_dir) { [images_root, 'adjacent-path' ].join('/') }
    let(:file_system) { PhotoFS::FS::Test.new( { files:  files } ) }

    before(:example) do
      create_images [path1, path2]

      allow(file_system).to receive(:pwd).and_return(working_dir)
      allow(PhotoFS::FS).to receive(:images_path).and_return(images_root)
      allow(PhotoFS::FS::FileMonitor).to receive(:new).and_return(instance_double('FileMonitor', paths:  paths))
    end

    it 'should add images under the path that are not in the database' do
      cli.execute ['import', 'images', search_path]

      expect(PhotoFS::Data::Image.find_by_image_file_paths [path3]).to contain_exactly(an_instance_of PhotoFS::Data::Image)
    end
  end

  describe :import_tags do
    let(:path_arg) { [images_root, 'a'].join('/') }
    let(:path1) { '1.jpg' }
    let(:path2) { '2.jpg' }
    let(:image_paths) { [path1, path2].map { |p| [images_root, p].join('/') } }
    let(:json_file) { '/exported-file.json' }
    let(:files) { image_paths + [json_file] }
    let(:working_dir) { [images_root, 'some-dir'].join('/') }

    let(:file_system) { PhotoFS::FS::Test.new( { files: files } ) }

    before(:example) do
      create_images [path1, path2]

      allow(file_system).to receive(:pwd).and_return(:working_dir)
      allow(PhotoFS::FS).to receive(:images_path).and_return(images_root)
    end

    context 'when path argument is a JSON file' do
      let(:json) do
  <<-EOS
  { "tags": [
    { "name": "tree", "paths": ["1.jpg", "2.jpg"] },
    { "name": "bark", "paths": ["2.jpg"] },
    { "name": "root", "paths": [] },
    { "name": "noent", "paths": ["NOENT.jpg"]}
  ] }
  EOS
      end

      before(:example) do
        allow(file_system).to receive(:read_file).with(json_file).and_return(json)
      end

      it 'should add all tags applied to images in the repository' do
        cli.execute ['import', 'tags', json_file]

        tags = PhotoFS::Data::TagSet.new

        expect(tags.find_by_name(['tree', 'bark']).map { |t| t.name }).to contain_exactly('tree', 'bark')
      end

      it 'should apply all prescribed tags to images in the repository' do
        cli.execute ['import', 'tags', json_file]

        tags = PhotoFS::Data::TagSet.new

        expect(tags.find_by_name(['tree', 'bark']).reduce { |tree, bark| tree & bark }.all.map { |i| i.path }).to contain_exactly('2.jpg')
      end

      context 'when there are tags not applied to any image' do
        let(:json) { '{ "tags": [{ "name": "tree", "paths": []} ] }' }

        it 'should still import those tags' do
          cli.execute ['import', 'tags', json_file]

          tags = PhotoFS::Data::TagSet.new

          expect(tags.find_by_name(['tree'])).to contain_exactly(an_instance_of PhotoFS::Core::Tag)
        end
      end

      context 'a tag is applied to images in the set and out of the set' do
        let(:json) { '{ "tags": [{ "name": "tree", "paths": ["1.jpg", "some-other-image"]} ] }' }

        it 'should apply the tag to the images in the set' do
          cli.execute ['import', 'tags', json_file]

          tags = PhotoFS::Data::TagSet.new

          expect(tags.find_by_name('tree').images[0].path).to eq('1.jpg')
        end
      end

      context 'a tag already exists in the repository' do
        let(:image) { PhotoFS::Core::Image.new '1.jpg' }
        let(:tag) { PhotoFS::Core::Tag.new('tree', { set: [image].to_set }) }

        before(:example) do
          tags = PhotoFS::Data::TagSet.new
          tags.add? tag
        end

        context 'and the tag in the import file does not have any images' do
          let(:json) { '{ "tags": [ { "name": "tree", "paths": []} ] }' }

          it 'should not untag any of the existing tagged images' do
            cli.execute ['import', 'tags', json_file]

            tags = PhotoFS::Data::TagSet.new

            expect(tags.find_by_name('tree').images.length).to eq(1)
          end
        end

        context 'and the tag in the import file has a different set of images' do
          let(:json) { '{ "tags": [ { "name": "tree", "paths": ["2.jpg"]} ] }' }

          it 'should apply tag to any additional images in the import file' do
            cli.execute ['import', 'tags', json_file]

            tags = PhotoFS::Data::TagSet.new

            expect(tags.find_by_name('tree').images.length).to eq(2)
          end
        end
      end
    end
  end

  describe :prune do
    let(:path1) { 'a/b/c/1.jpg' }
    let(:path2) { 'a/b/c/2.jpg' }
    let(:path3) { 'a/b/c/3.jpg' }
    let(:path4) { 'a/x/y/z.jpg' }
    let(:files) { [path1, path2].map { |p| [images_root, p].join('/') } }
    let(:images) { [path1, path2, path3, path4] }
    let(:remaining_images) { PhotoFS::Data::Image.all.map { |i| i.path } }

    let(:file_system) { PhotoFS::FS::Test.new( { files:  files } ) }

    before(:each) do
      create_images images
    end

    it 'should remove images that are missing from the file system' do
      cli.execute ['prune', [images_root, 'a/b/c'].join('/') ]

      expect(remaining_images).to contain_exactly(path1, path2, path4)
    end

    it 'should descend the directory tree to prune' do
      cli.execute ['prune', [images_root, 'a'].join('/') ]

      expect(remaining_images).to contain_exactly(path1, path2)
    end

    it 'should prune from the path above the file, if given' do
      cli.execute ['prune', [images_root, 'a/b/c/1.jpg'].join('/') ]

      expect(remaining_images).to contain_exactly(path1, path2, path4)
    end
  end # :prune

  describe :retag do
    let(:image_path1) { 'a/b/c/1.jpg' }
    let(:image_path2) { 'a/b/c/2.jpg' }
    let(:unimported_file) { [images_root, 'a/b/c/not-imported.jpg'].join('/') }
    let(:image_paths) { [image_path1, image_path2] }
    let(:files) { image_paths.map { |p| [images_root, p].join('/') } + [unimported_file] }
    let(:image_records) { create_images image_paths }

    let(:file_system) { PhotoFS::FS::Test.new(files: files) }

    let(:good_tag_record) { create :tag, name: 'good' }
    let(:bad_tag_record) { create :tag, name: 'bad' }
    let(:tag_records) { [good_tag_record, bad_tag_record] }

    context 'when all images exist' do
      before(:example) do
        image_records
      end

      context 'old and new tags exist' do
        before(:example) do
          tag_records

          good_tag_record.images = image_records

          good_tag_record.save
        end

        it 'should remove any applications of old tag to images' do
          cli.execute ['retag', 'good', 'bad', files[0], files[1]]

          expect(PhotoFS::Data::Tag.from_tag(good_tag_record.to_simple).images).to be_empty
        end

        it 'should apply new tag to images' do
          cli.execute ['retag', 'good', 'bad',  files[0], files[1]]

          expect(PhotoFS::Data::Tag.from_tag(bad_tag_record.to_simple).images).to contain_exactly(*image_records)
        end
      end

      context 'when new tag does not yet exist' do
        before(:example) do
          good_tag_record
        end

        it 'should create it' do
          cli.execute ['retag', 'good', 'bad',  files[0], files[1]]

          expect(PhotoFS::Data::Tag.from_tag(double('Tag', name: 'bad'))).to be_an_instance_of(PhotoFS::Data::Tag)
        end
      end

      context 'when multiple tags are specified' do
        subject { cli.execute ['retag', 'good better', 'bad worse',  files[0], files[1]] }

        before(:example) do
          good_tag_record.images = image_records

          good_tag_record.save

          subject
        end

        it 'should create the first new tag' do
          expect(PhotoFS::Data::Tag.from_tag(double('Tag', name: 'bad'))).to be_an_instance_of(PhotoFS::Data::Tag)
        end

        it 'should create the second new tag' do
          expect(PhotoFS::Data::Tag.from_tag(double('Tag', name: 'worse'))).to be_an_instance_of(PhotoFS::Data::Tag)
        end

        it 'should add images to first new tag' do
          expect(PhotoFS::Data::Tag.from_tag(double('Tag', name: 'bad')).images).to contain_exactly(*image_records)
        end

        it 'should add images to second new tag' do
          expect(PhotoFS::Data::Tag.from_tag(double('Tag', name: 'worse')).images).to contain_exactly(*image_records)
        end

        it 'should remove any applications of first old tag to images' do
          expect(PhotoFS::Data::Tag.from_tag(double('Tag', name: 'good')).images).to be_empty
        end
      end # multiple tags
    end

    context 'if one of the images is not yet imported' do
      it { expect { cli.execute ['retag', 'good', 'bad', files[0], unimported_file] }.to output(/not imported/).to_stdout }
    end
  end # :retag
end
