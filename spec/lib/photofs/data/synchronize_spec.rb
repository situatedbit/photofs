require 'photofs/data/synchronize'
require 'photofs/fs'
require 'photofs/fs/test'

describe PhotoFS::Data::Synchronize::Lock do
  let(:file_system) { PhotoFS::FS::Test.new }
  let(:lock) { PhotoFS::Data::Synchronize::Lock.new 'test.lock' }

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)
    allow(lock).to receive(:lock_file).and_return('test.lock')
  end

  describe :grab do
    it 'should lock with lock file' do
      expect(file_system).to receive(:lock).with('test.lock')

      lock.grab {}
    end

    it 'should yield to the passed block' do
      expect { |b| lock.grab(&b) }.to yield_control
    end

    describe 'increment callback' do
      let(:callback) { instance_double('Proc', call: nil) }

      before(:example) do
        lock.register_on_detect_count_increment callback

        lock.instance_variable_set(:@previous_count, 5)
      end

      context 'when the count is incremented' do
        before(:example) do
          allow(lock).to receive(:count).and_return(6)
        end

        it 'should trigger detected count increment callback' do
          expect(callback).to receive(:call).with(lock)

          lock.grab {}
        end
      end

      context 'when the count is not incremented between calls' do
        before(:example) do
          allow(lock).to receive(:count).and_return(5)
        end

        it 'should not trigger count increment callback' do
          expect(callback).not_to receive(:call)

          lock.grab {}
        end
      end
    end # increment callback
  end # :grab

end
