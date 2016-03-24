require 'photofs/data/repository'

describe PhotoFS::Data::Repository do
  let(:klass) do
    class RepositoryKlass
      include PhotoFS::Data::Repository
    end
  end

  let(:repository) { klass.new }

  describe :save_record_object_map do
    let!(:record_1) { create :image }
    let!(:record_2) { create :image }
    let!(:record_3) { create :image }

    let(:object_1) { record_1.to_simple }
    let(:object_2) { record_2.to_simple }
    let(:object_3) { record_3.to_simple }

    let(:record_object_map) do
      { record_1 => object_1, record_2 => object_2, record_3 => object_3 }
    end

    context 'when there are dirty objects in the cache' do
      before(:example) do
        allow(record_2).to receive(:consistent_with?).with(object_2).and_return(false)
        allow(record_3).to receive(:consistent_with?).with(object_3).and_return(false)
      end

      it 'should update each dirty record' do
        expect(record_2).to receive(:update_from).with(object_2)
        expect(record_3).to receive(:update_from).with(object_3)

        repository.save_record_object_map(record_object_map)
      end

      it 'should save each dirty image record' do
        expect(record_2).to receive :save!
        expect(record_3).to receive :save!

        repository.save_record_object_map(record_object_map)
      end

      it 'should not save clean records' do
        expect(record_1).not_to receive :save!

        repository.save_record_object_map(record_object_map)
      end
    end
  end # :save_record_object_map

  describe :load_all_records do
    it 'should be implemented and tested'
  end
end
