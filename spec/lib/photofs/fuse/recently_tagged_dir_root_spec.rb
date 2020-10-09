require 'photofs/core/tag'
require 'photofs/core/tag_set'
require 'photofs/data/tag'
require 'photofs/fuse/recently_tagged_dir_root'
require 'photofs/fuse/tag_dir'

describe PhotoFS::Fuse::RecentlyTaggedDirRoot do
  let(:dir) do
    PhotoFS::Fuse::RecentlyTaggedDirRoot.new(
      'recent',
      instance_double(PhotoFS::Core::TagSet),
      double('ImageSet')
    )
  end

  describe :node_hash do
    let(:tags) do
      [
        instance_double(PhotoFS::Core::Tag, name: 'tree'),
        instance_double(PhotoFS::Core::Tag, name: 'shrub')
      ]
    end

    before(:example) do
        allow(PhotoFS::Data::Tag).to receive(:recently_applied).and_return(tags)
    end

    it 'should create tag dirs for each recently applied tag' do
      expect(PhotoFS::Fuse::TagDir).to receive(:new).twice

      dir.send :node_hash
    end

    it 'should create tag dirs with query tag names matching the tag name' do
      tags.each do |tag|
        expect(PhotoFS::Fuse::TagDir).to receive(:new).with(tag.name, anything, hash_including(query_tag_names: [tag.name]))
      end

      dir.send :node_hash
    end

    it 'should include an entry for each tag recently applied tag' do
      expect(dir.send(:node_hash).keys).to match_array(tags.map(&:name))
    end
  end
end
