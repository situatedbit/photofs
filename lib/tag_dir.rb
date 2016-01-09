require_relative 'dir'

module PhotoFS
  class TagDir < PhotoFS::Dir
    def initialize(name, tags, query_tag_names=[])
      @tags = tags
      @query_tag_names = query_tag_names

      super(name, parent)
    end

    def add(node)
      raise NotImplementedError
    end

    def stat
      stat_hash = { :atime => Time.now,
                    :ctime => Time.now,
                    :mtime => Time.now,
                    :size => size }

      mode = Stat.add Stat::MODE_READ_ONLY, Stat::PERM_USER_WRITE

      RFuse::Stat.directory(mode, stat_hash)
    end

    protected

    def node_hash
      Hash[ (files + dirs).map { |n| [n.name, n] } ]
    end

    private

    def dirs
      dir_tags.map do |tag|
        TagDir.new(tag.name, @tags, @query_tag_names + [tag.name])
      end
    end

    def dir_tags
      @tags.find_by_image(file_images) - query_tags
    end

    def files
      file_images.map { |image| File.new(image.name, image.path, self) }
    end

    def file_images
      TagSet.intersection(query_tags).images
    end

    def size
      node_hash.values.reduce(0) { |size, node| size + node.name.length }
    end

    def query_tags
      @tags.find_by_name(@query_tag_names)
    end

  end
end