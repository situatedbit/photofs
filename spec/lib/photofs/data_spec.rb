require 'photofs/data'

describe PhotoFS::Data do
  let(:klass) { PhotoFS::Data }

  describe '#consistent_arrays?' do
    context 'when arrays are empty' do
      let(:records) { [] }
      let(:objects) { [] }

      it 'should be true' do
        expect(klass.consistent_arrays?(records, objects)).to be true
      end
    end

    context 'when lengths are different' do
      let(:records) { [] }
      let(:objects) { [instance_double('PhotoFS::Core::Image')] }

      it 'should be false' do
        expect(klass.consistent_arrays?(records, objects)).to be false
      end
    end

    context 'when one image is different' do
      let(:record) { build :image }
      let(:object) { instance_double('PhotoFS::Core::Image') }
      let(:records) { [record] }
      let(:objects) { [object] }

      before(:example) do
        allow(record).to receive(:consistent_with?).with(object).and_return(false)
      end

      it 'should be false' do
        expect(klass.consistent_arrays?(records, objects)).to be false
      end
    end

    context 'when all images are consistent' do
      let(:records) { [build(:image), build(:image)] }
      let(:objects) { [instance_double('PhotoFS::Core::Image'), instance_double('PhotoFS::Core::Image')] }

      before(:example) do
        allow(records[0]).to receive(:consistent_with?).with(objects[0]).and_return(true)
        allow(records[1]).to receive(:consistent_with?).with(objects[1]).and_return(true)
      end

      it 'should be true' do
        expect(klass.consistent_arrays?(records, objects)).to be true
      end
    end
  end # :consistent_arrays?

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

        klass.save_record_object_map(record_object_map)
      end

      it 'should save each dirty image record' do
        expect(record_2).to receive :save!
        expect(record_3).to receive :save!

        klass.save_record_object_map(record_object_map)
      end

      it 'should not save clean records' do
        expect(record_1).not_to receive :save!

        klass.save_record_object_map(record_object_map)
      end
    end
  end # :save_record_object_map
end
