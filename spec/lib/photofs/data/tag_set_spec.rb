require 'photofs/data/tag_set'

describe PhotoFS::Data::TagSet do
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
    it 'should send :save! to all dirty tags'
  end

  describe :tags do
    it 'should cache all records and simple objects'
    it 'should be an array of all tags as simple objects'
  end

end
