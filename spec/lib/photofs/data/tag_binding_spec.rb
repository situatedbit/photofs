require 'photofs/data/tag_binding'

describe PhotoFS::Data::TagBinding, type: :model do
  it { should belong_to(:tag) }
  it { should belong_to(:image) }
end
