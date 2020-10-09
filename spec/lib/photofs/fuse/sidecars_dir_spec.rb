require 'photofs/fuse/file'
require 'photofs/fuse/sidecars_dir'

describe PhotoFS::Fuse::SidecarsDir do
  let(:dir) { PhotoFS::Fuse::SidecarsDir.new('sidecars') }

  before(:example) do
    allow(PhotoFS::FS).to receive(:expand_path) { |arg| arg }
  end

  describe :node_hash do
    subject { dir.send(:node_hash) }

    before(:example) do
      allow(dir).to receive(:sidecar_images).and_return(sidecar_images)
    end

    context 'there are no sidecar images' do
      let(:sidecar_images) { [] }

      it { expect(subject).to be_empty }
    end

    context 'there are two sidecar images' do
      let(:image1) { double('Image', path: 'image 1') }
      let(:image2) { double('Image', path: 'image 2') }
      let(:sidecar_images) { [image1, image2] }
      let(:a_file) { an_instance_of(PhotoFS::Fuse::File) }

      it 'should be a mapping of their names to files' do
        expect(subject).to match('image 1' => a_file, 'image 2' => a_file)
      end
    end
  end
end
