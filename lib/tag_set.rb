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

    # returns images
    def find_intersection(tag_names)
      tag_set = find(tag_names)

      return [] if tag_set.nil? || tag_set.empty?

      tag_set[1..-1].reduce(tag_set.first.images) { |images, tag| tag.intersection(images) }
    end

    def from(images)
      images = [images].flatten # normalize as array

      hash = image_tags_hash

      images.map { |image| hash[image] || [] }.flatten.uniq
    end

    private

    def tags
      @tags
    end

    def image_tags_hash
      hash = {}

      tags.values.each do |tag|
        tag.images.each { |i| hash[i] = hash.fetch(i, []) + [tag] }
      end

      hash
    end

  end
end
