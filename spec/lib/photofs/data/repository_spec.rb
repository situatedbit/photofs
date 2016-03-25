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
    let(:active_record_class) { double('record class') }

    context 'when there are records cached' do
      let!(:record) { double('record', :id => 42, :path => 'some-path') }
      let(:object) { double('object', :path => 'some-path') }
      let!(:uncached_record) { double('record') }
      let(:uncached_object) { double('object') }
      let(:record_object_map) { { record => object } }
      let(:fully_loaded_record_object_map) { { record => object, uncached_record => uncached_object } }

      before(:example) do
        allow(active_record_class).to receive_message_chain(:where, :not).and_return([uncached_record])
        allow(uncached_record).to receive(:to_simple).and_return(uncached_object)
      end

      it 'should fill the cache with all simple objects not already in the cache' do
        expect(repository.load_all_records record_object_map, active_record_class).to eq(fully_loaded_record_object_map)
      end
    end
  end # :load_all_records
end
