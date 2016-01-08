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

      if tag_set.nil? || tag_set.empty?
        []
      elsif tag_set.length == 1
        tag_set.first.images
      else
        (tag_set.first & tag_set[1..-1]).images
      end
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
