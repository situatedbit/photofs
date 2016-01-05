require_relative 'tag'

module PhotoFS
  class TagSet
    def initialize
      @tags = {}
    end

    def all
      tags.values
    end

    def find_or_create(tag_name)
      tag = find(tag_name) || Tag.new(tag_name)

      tags[tag_name] = tag
    end

    def find(query)
      if query.respond_to? :map
        query.map { |n| tags[n] }.select { |t| not t.nil? }
      else
        tags[query]
      end
    end

    def find_intersection(tag_names)
      tag_set = find(tag_names)

      return [] if tag_set.nil? || tag_set.empty?

      tag_set[1..-1].reduce(tag_set.first.images) { |images, tag| tag.intersection(images) }
    end

    private

    def tags
      @tags
    end
  end
end
