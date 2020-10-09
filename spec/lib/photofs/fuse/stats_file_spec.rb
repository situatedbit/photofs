require 'photofs/fuse/stats_file'

describe PhotoFS::Fuse::StatsFile do
  let(:file) { PhotoFS::Fuse::StatsFile.new 'stats', tags: tag_set }

  let(:tag_set) { instance_double('TagSet', all: [tag1, tag2]) }
  let(:image) { PhotoFS::Core::Image }

  let(:tag1) { instance_double('Tag', name: 'good') }
  let(:tag2) { instance_double('Tag', name: 'bad') }
  let(:tag1_images) { [image.new('/1/a.jpg'), image.new('/1/c.jpg'), image.new('/1/b.jpg')] }
  let(:tag2_images) { [image.new('/1/d.jpg'), image.new('/1/a.jpg')] }

  describe :contents do
    subject { file.contents }

    before(:example) do
      allow(tag1).to receive(:images).and_return(tag1_images)
      allow(tag2).to receive(:images).and_return(tag2_images)
    end

    it { expect(subject).to match(/^good: 3$/) }
    it { expect(subject).to match(/^bad: 2$/) }

    context 'when there are no tags' do
      let(:tag_set) { instance_double('TagSet', all: []) }

      it { expect(subject).to be_empty }
    end
  end

  describe :read_contents do
    let(:contents) { '0123456789' }

    before(:example) do
      allow(file).to receive(:contents).and_return(contents)
    end

    it { expect(file.read_contents(100, 0)).to eq contents }
    it { expect(file.read_contents(5, 0)).to eq '01234' }
    it { expect(file.read_contents(10, 5)).to eq '56789' }
    it { expect(file.read_contents(2, 5)).to eq '56' }
    it { expect(file.read_contents(10, 100)). to eq '' }
  end

  describe :stat do
    let(:contents) { '0123456789' }

    before(:example) do
      allow(file).to receive(:contents).and_return(contents)
    end

    subject { file.stat }

    it { expect(subject.size).to eq file.contents.length }

    it { expect(subject.mode & PhotoFS::Fuse::Stat::MODE_MASK).to eq(PhotoFS::Fuse::Stat::MODE_READ_ONLY) }
  end

end
