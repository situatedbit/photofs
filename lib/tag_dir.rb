require_relative 'dir'

module PhotoFS
  class TagDir < PhotoFS::Dir
    def initialize(name, tags, query_tag_names=[], parent=nil)
      @tags = tags
      @query_tag_names = query_tag_names

      super(name, parent)
    end

    def mkdir(tag_name)
      raise Errno::EPERM.new(tag_name) unless is_tags_root?

      tag = Tag.new tag_name

      raise Errno::EEXIST.new(tag_name) if dir_tags.include?(tag)

      @tags.add?(tag)
    end

    def rmdir(tag_name)
      tag = @tags.find_by_name tag_name

      raise Errno::ENOENT.new(tag_name) unless tag && dir_tags.include?(tag)

      if is_tags_root?
        @tags.delete tag
      else
        tag.subtract images
      end
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
        TagDir.new(tag.name, @tags, @query_tag_names + [tag.name], self)
      end
    end

    def dir_tags
      if is_tags_root?
        @tags.all
      else
        @tags.find_by_image(images.all) - query_tags
      end
    end

    def files
      images.all.map { |image| File.new(image.name, image.path, self) }
    end

    def images
      TagSet.intersection(query_tags)
    end

    def is_tags_root?
      @query_tag_names.empty?
    end

    def size
      node_hash.values.reduce(0) { |size, node| size + node.name.length }
    end

    def query_tags
      @tags.find_by_name(@query_tag_names)
    end

  end
end
