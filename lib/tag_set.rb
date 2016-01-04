require_relative 'tag'

module PhotoFS
  class TagSet
    def initialize
      @tags = {}
    end

    def find(tag_name)
      tag = @tags[tag_name] || Tag.new(tag_name)

      @tags[tag_name] = tag
    end
  end
end
