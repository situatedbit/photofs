require 'photofs/fuse/dir'
require 'photofs/fuse/tag_dir'
require 'photofs/data/tag'

module PhotoFS::Fuse
  class RecentlyTaggedDirRoot < PhotoFS::Fuse::Dir
    def initialize(name, tags, images_domain, options = {})
      @tags = tags
      @images_domain = images_domain
      @config = options[:config] || {}

      super(name, options)
    end

    def clear_cache
      @node_hash = nil
    end

    protected

    def node_hash
      @node_hash ||= tag_nodes
    end

    private

    def tag_count
      # even if falsy via 0, default to 15
      @config.dig('fs', 'recently-applied-tags-count') || 15
    end

    def tag_nodes
      PhotoFS::Data::Tag.recently_applied(tag_count).reduce({}) do |name_map, tag|
        options = { query_tag_names: [tag.name], parent: self, images: @images_domain }
        dir = PhotoFS::Fuse::TagDir.new(tag.name, @tags, options)

        name_map.merge Hash[tag.name, dir]
      end
    end
  end
end
