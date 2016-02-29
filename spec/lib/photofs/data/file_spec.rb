require 'photofs/data/file'

describe PhotoFS::Data::File, type: :model do
  it { should validate_presence_of(:path) }
  it { should validate_uniqueness_of(:path) }
end
