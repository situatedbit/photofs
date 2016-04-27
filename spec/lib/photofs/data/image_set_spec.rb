require 'photofs/core/image_set'
require 'photofs/data/image_set'
require 'photofs/data/image'

describe PhotoFS::Data::ImageSet do
  let(:image_set) { PhotoFS::Data::ImageSet.new }

  describe :& do
    let(:other_set) { PhotoFS::Core::ImageSet.new }

    subject { image_set.&(other_set).to_a }

    context 'when the image set is empty' do
      before(:example) do
        allow(PhotoFS::Data::Image).to receive(:from_images).and_return([])
        other_set.add instance_double('Image', :path => '/a/file.jpg')
      end

      it { should be_empty }
    end

    context 'when the parameter is empty' do
      before(:example) do
        create :image
      end

      it { should be_empty }
    end

    context 'when the intersection is empty' do
      before(:example) do
        create_image '/a/b/c.jpg'
        other_set.add PhotoFS::Core::Image.new('/1/2/3.jpg')
      end

      it { should be_empty }
    end

    context 'when there is an intersection' do
      let!(:image_records) { [create(:image), create(:image)] }
      let(:intersection) { [image_records[0].to_simple] }

      before(:example) do
        intersection.each { |i| other_set.add i }
        other_set.add PhotoFS::Core::Image.new('/a/b/c/some-other-image.jpg')
      end

      it { should contain_exactly(*intersection) }
    end
  end # &

  describe :add do
    let(:image) { instance_double('PhotoFS::Core::Image') }
    let(:image_record) { instance_double('PhotoFS::Data::Image', {:save! => nil}) }

    before(:example) do
      allow(PhotoFS::Data::Image).to receive(:new_from_image).with(image).and_return(image_record)
    end

    it 'should insert into database with an active record object' do
      expect(image_record).to receive(:save!)

      image_set.add image
    end

    it 'should add image to the local cache' do
      expect(image_set.instance_variable_get :@record_object_map).to receive(:[]=).with(image_record, image)

      image_set.add image
    end

    context 'when the image record is invalid' do
      let(:image_record) { build(:image) }

      before(:example) do
        allow(image_record).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(image_record))
      end

      it 'should throw an exception if not unique on path' do
        expect { image_set.add image }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end # :add

  describe :empty? do
    it 'should return count on Data::Image' do
      expect(PhotoFS::Data::Image).to receive(:count)

      image_set.empty?
    end
  end

  describe :find_by_path do
    let(:path) { 'some/path.jpg' }
    let(:image_object) { instance_double('PhotoFS::Core::Image') }

    it 'should be the dereferenced result from find_by_paths' do
      allow(image_set).to receive(:find_by_paths).with([path]).and_return({path => image_object})

      expect(image_set.find_by_path path).to be(image_object)
    end
  end # :find_by_path

  describe :find_by_paths do
    let(:image_record_1) { create(:image) }
    let(:image_record_2) { create(:image) }
    let(:path_1) { image_record_1.to_simple.path }
    let(:path_2) { image_record_2.to_simple.path }
    let(:path_3) { '/not/in/database.jpg' }
    let(:record_object_map) { image_set.instance_variable_get(:@record_object_map) }

    it 'should be a hash of paths and simple images' do 
      expect(image_set.find_by_paths([path_1, path_2])[path_1]).to eq(image_record_1.to_simple)
      expect(image_set.find_by_paths([path_1, path_2])[path_2]).to eq(image_record_2.to_simple)
    end

    it 'should add all returned images to the cache' do
      expect(record_object_map).to receive(:[]=).with(image_record_1, image_record_1.to_simple)
      expect(record_object_map).to receive(:[]=).with(image_record_2, image_record_2.to_simple)

      image_set.find_by_paths [path_1, path_2]
    end

    context 'when one of the paths is not in the database' do
      let(:paths) { image_set.find_by_paths [path_1, path_3] }

      it 'should include the missing path in hash keys' do
        expect(paths.has_key? path_3).to be true
      end

      it 'should include the missing path bound to nil' do
        expect(paths[path_3]).to be_nil
      end
    end

    context 'when an image is already in the cache' do
      let(:cached_image) { instance_double('PhotoFS::Core::Image', :path => image_record_1.path) }
      let(:an_image) { an_instance_of(PhotoFS::Core::Image) }
      let(:paths) { image_set.find_by_paths [path_1, path_2] }

      before(:example) do
        allow(record_object_map).to receive(:[]).with(image_record_1).and_return(cached_image)
        allow(record_object_map).to receive(:[]).with(image_record_2).and_return(nil)
      end

      it 'should not update the cache with cached record' do
        expect(record_object_map).not_to receive(:[]=).with(image_record_1, an_image)

        image_set.find_by_paths [path_1, path_2]
      end

      it 'should return the cached object' do
        expect(paths[path_1]).to eq(cached_image)
      end
    end
  end # :find_by_paths

  describe :import do
    let(:path_1) { '/a/b/1.jpg' }
    let(:path_2) { '/a/b/2.jpg' }
    let(:paths) { [path_1, path_2] }

    before(:example) do
      allow(PhotoFS::Data::Image).to receive(:exist_by_paths).with(paths).and_return([path_1])
    end

    subject { image_set.import paths }

    it { should contain_exactly(an_instance_of PhotoFS::Core::Image) }

    it { should contain_exactly(have_attributes(:path => path_2)) }

    it 'should add images for paths not in the database' do
      expect(image_set).to receive(:add).with(have_attributes :path => path_2)

      image_set.import paths
    end

    it 'should not add images for paths already in the database' do
      expect(image_set).not_to receive(:add).with(have_attributes(:path => path_1))

      image_set.import paths
    end
  end

  describe :save! do
    it 'should call the Data module method' do
      expect(image_set).to receive(:save_record_object_map).with(image_set.instance_variable_get(:@record_object_map))

      image_set.save!
    end
  end

# protected
  describe :set do
    context 'when there are items in database' do
      let(:images) { PhotoFS::Data::Image.all }

      before(:example) do
        2.times { create :image }
      end

      it 'should return objects from the records in the database' do
        expect(image_set.send :set).to contain_exactly(images[0].to_simple, images[1].to_simple)
      end
    end
  end # :set

end
