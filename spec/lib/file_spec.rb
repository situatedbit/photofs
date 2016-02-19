require 'file'

describe PhotoFS::File do
  let(:target_path) { '~/garbage' }
  let(:absolute_path) { '/tmp/garbage' }
  let(:file) { PhotoFS::File.new('garbage', target_path) }

  before(:each) do
    allow(File).to receive(:absolute_path).and_return(absolute_path)
    allow(File).to receive(:exist?).and_return(true)
  end

  describe "initialize method" do
    it "should take a target path" do
      expect(file.target_path).to eq(absolute_path)
    end

    it "should balk at a target path that does not exist" do
      allow(File).to receive(:exist?).and_return(false)

      expect { file }.to raise_error(ArgumentError)
    end
  end

  describe "stat method" do
    before(:each) do
      allow(PhotoFS::Stat).to receive(:stat_hash).and_return({})
      allow(File).to receive(:stat).and_return({})
    end

    it "should return node type link" do
      expect(file.stat.mode & RFuse::Stat::S_IFMT).to eq(RFuse::Stat::S_IFLNK)
    end

    it "should set nlink attribute to 1" do
      expect(file.stat.nlink).to eq(1)
    end

    it "should set size attribute to length of link target" do
      expect(file.stat.size).to eq(absolute_path.length)
    end

    it "should be read only" do
      expect(file.stat.mode & PhotoFS::Stat::MODE_MASK).to eq(PhotoFS::Stat::MODE_READ_ONLY)
    end
  end
end
