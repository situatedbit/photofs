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
      @tags.intersection(query_tags).images
    end

    def query_tags
      @tags.find_by_name(@query_tag_names)
    end

  end
end
