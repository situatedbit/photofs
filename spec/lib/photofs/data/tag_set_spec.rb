require 'photofs/data/tag_set'

describe PhotoFS::Data::TagSet do
  let(:tag_set) { PhotoFS::Data::TagSet.new }

  describe :add? do
    it 'should check the cache for the tag'

    it 'should check the database for the tag'

    context 'the tag is not in the cache or database' do
      it 'should add the simple object to the cache'
      it 'should add the record to the cache'
      it 'should save the new record to the database'
    end

    context 'the tag is in the cache' do
      it 'should return nil'
    end

    context 'the tag is in the database' do
      it 'should return nil'
    end
  end

  describe :delete do
    it 'should remove the tag from the cache'
    it 'should remove the tag record from the database'
  end

  describe :save! do
    it 'should call the Data module method' do
      expect(tag_set).to receive(:save_record_object_map).with(tag_set.instance_variable_get(:@record_object_map))

      tag_set.save!
    end
  end

  # protected
  describe :tags do
    let(:tag_1) { instance_double('PhotoFS::Core::Tag') }
    let(:tag_2) { instance_double('PhotoFS::Core::Tag') }
    let(:record_object_map) { tag_set.instance_variable_get(:@record_object_map) }

    before(:example) do
      allow(tag_set).to receive(:load_all_records).with(record_object_map, PhotoFS::Data::Tag)
      allow(record_object_map).to receive(:values).and_return([tag_1, tag_2])
    end

    it 'should load all records into the cache' do
      expect(tag_set).to receive(:load_all_records).with(tag_set.instance_variable_get(:@record_object_map), PhotoFS::Data::Tag)

      tag_set.send :tags
    end

    it 'should be all of the simple objects' do
      expect(tag_set.send :tags).to contain_exactly(tag_1, tag_2)
    end
  end # :tags

end
