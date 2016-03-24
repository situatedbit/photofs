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

end
