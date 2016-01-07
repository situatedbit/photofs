require_relative 'dir'

module PhotoFS
  class TagDir < PhotoFS::Dir
    attr_reader :query_tags

    def initialize(name, tags, query_tags=[])
      @tags = tags
      @query_tags = query_tags

      super(name, parent)
    end

    def add(node)
      raise "Not yet implemented"
    end

    protected

    def node_hash
      Hash[ (files + dirs).map { |n| [n.name, n] } ]
    end

    private

    def tags
      @tags
    end

    def files
      file_images.map { |image| File.new(image.name, image.path, self) }
    end

    def dirs
      dir_tags.map do |tag|
        TagDir.new(tag.name, tags, query_tags + [tag.name])
      end
    end

    def dir_tags
      tags.from(file_images) - query_tags
    end

    def file_images
      tags.find_intersection(query_tags)
    end

  end
end
