require 'photofs/data/image_set'

describe PhotoFS::Data::ImageSet do
  describe :add do
    it 'should insert into database with an active record object'

    it 'should add image to the local cache'

    it 'should throw an exception if not unique on path'
  end

  describe :empty? do
    it 'should return count on Data::Image'
  end

  describe :find_by_path do
    it 'should fetch using path attribute'

    it 'should add the returned image to the cache'

    context 'when an image is already in the cache' do
      it 'should return the cached object'
    end
  end

  describe :set do
    it 'should return all Images as simple objects in a set'
  end
end
