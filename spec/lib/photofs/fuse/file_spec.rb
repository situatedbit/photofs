require 'photofs/fuse/file'

describe PhotoFS::Fuse::File do
  let(:target_path) { '~/garbage' }
  let(:file) { PhotoFS::Fuse::File.new('garbage', target_path) }

  describe :new do
    it "should take a target path" do
      expect(file.target_path).to be target_path
    end
  end

  describe "stat method" do
    before(:each) do
      allow(PhotoFS::Fuse::Stat).to receive(:stat_hash).and_return({})
      allow(File).to receive(:stat).and_return({})
    end

    it "should return node type link" do
      expect(file.stat.mode & RFuse::Stat::S_IFMT).to eq(RFuse::Stat::S_IFLNK)
    end

    it "should set nlink attribute to 1" do
      expect(file.stat.nlink).to eq(1)
    end

    it "should set size attribute to length of link target" do
      expect(file.stat.size).to eq target_path.length
    end

    it "should be read only" do
      expect(file.stat.mode & PhotoFS::Fuse::Stat::MODE_MASK).to eq(PhotoFS::Fuse::Stat::MODE_READ_ONLY)
    end
  end
end
