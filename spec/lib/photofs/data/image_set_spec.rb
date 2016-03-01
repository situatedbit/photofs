require 'photofs/data/image_set'

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
    let!(:record_1) { create :image }
    let!(:record_2) { create :image }
    let!(:record_3) { create :image }

    let(:image_1) { record_1.to_simple }
    let(:image_2) { record_2.to_simple }
    let(:image_3) { record_3.to_simple }

    let(:record_object_map) do
      { record_1 => image_1, record_2 => image_2, record_3 => image_3 }
    end

    before(:example) do
      image_set.instance_variable_set(:@record_object_map, record_object_map)
    end

    context 'when there are dirty images in the cache' do
      before(:example) do
        allow(record_2).to receive(:consistent_with?).with(image_2).and_return(false)
        allow(record_3).to receive(:consistent_with?).with(image_3).and_return(false)
      end

      it 'should update each dirty image record' do
        expect(record_2).to receive(:update_from).with(image_2)
        expect(record_3).to receive(:update_from).with(image_3)

        image_set.save!
      end

      it 'should save each dirty image record' do
        expect(record_2).to receive :save!
        expect(record_3).to receive :save!

        image_set.save!
      end

      it 'should not save clean records' do
        expect(record_1).not_to receive :save!
      end
    end
  end # :save!

# protected
  describe :set do
    context 'when there are items in database' do
      let(:count) { 2 }

      before(:example) do
        count.times { create(:image) }
      end

      it 'should have the same size as count' do
        expect(image_set.send(:set).size).to eq(count)
      end
    end

    context 'when there are images cached' do
      let!(:image_record) { create :image }
      let(:image_object) { image_record.to_simple }
      let!(:uncached_record) { create :image }
      let(:record_object_map) { { image_record => image_object } }

      before(:example) do
        image_set.instance_variable_set :@record_object_map, record_object_map
      end

      it 'should fill the cache with all simple objects not already in the cache' do
        expect(record_object_map).to receive(:[]=).with(uncached_record, any_args)

        image_set.send :set
      end

      it 'should not update the cached entries' do
        expect(record_object_map).not_to receive(:[]=).with(image_record, any_args)
      end

      it 'should include all images' do
        expect(image_set.send(:set).to_a).to contain_exactly(image_object, uncached_record.to_simple)
      end
    end
  end # :set
end
