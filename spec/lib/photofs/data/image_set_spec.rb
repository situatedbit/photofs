require 'photofs/data/image_set'
require 'photofs/data/image'

describe PhotoFS::Data::ImageSet do
  let(:image_set) { PhotoFS::Data::ImageSet.new }

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
    let(:image_record) { create(:image) }
    let(:path) { image_record.to_simple.path }

    it 'should be an simple image object' do
      expect(image_set.find_by_path(path).is_a? PhotoFS::Core::Image).to be true
    end

    it 'should add the returned image to the cache' do
      expect(image_set.instance_variable_get(:@record_object_map)).to receive(:[]=).with(image_record, image_record.to_simple)

      image_set.find_by_path path
    end

    context 'when the path is not in the database' do
      let(:path) { image_record.to_simple.path + 'nope' }

      it 'should be nil' do
        expect(image_set.find_by_path path).to be nil
      end
    end

    context 'when an image is already in the cache' do
      let(:cached_image) { instance_double('PhotoFS::Core::Image') }

      before(:example) do
        allow(image_set.instance_variable_get(:@record_object_map)).to receive(:[]).with(image_record).and_return(cached_image)
      end

      it 'should not update the cache' do
        expect(image_set.instance_variable_get(:@record_object_map)).not_to receive(:[]=)

        image_set.find_by_path path
      end

      it 'should return the cached object' do
        expect(image_set.find_by_path path).to be cached_image
      end
    end
  end # :find_by_path

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
