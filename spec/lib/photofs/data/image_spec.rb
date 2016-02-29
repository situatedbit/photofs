require 'photofs/data/image'

describe PhotoFS::Data::Image, type: :model do
  it { should validate_presence_of(:jpeg_file) }
  it { should validate_uniqueness_of(:jpeg_file_id) }
end
