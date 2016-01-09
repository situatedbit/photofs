require_relative 'tag'

module PhotoFS
  class TagSet

    # returns image set
    def self.intersection(tags)
      tags = [tags].flatten # normalize to array

      if tags.nil? || tags.empty?
        ImageSet.new
      elsif tags.length == 1
        ImageSet.new tags.first
      else
        tags.first & tags[1..-1]
      end
    end

    def initialize
      @tags = {}
    end

    def all
      @tags.values
    end

    def find_or_create(tag_name)
      tag = find_by_name(tag_name) || Tag.new(tag_name)

      @tags[tag_name] = tag
    end

    # returns array if tag_names is an array, a single tag otherwise
    def find_by_name(tag_names)
      if tag_names.respond_to? :map
        tag_names.map { |n| @tags[n] }.select { |t| not t.nil? }
      else
        @tags[tag_names]
      end
    end

    # returns array of tags which tag any of the images
    def find_by_image(images)
      images = [images].flatten # normalize to array

      hash = image_tags_hash

      images.map { |image| hash[image] || [] }.flatten.uniq
    end

    private

    def image_tags_hash
      hash = {}

      @tags.values.each do |tag|
        tag.images.each { |i| hash[i] = hash.fetch(i, []) + [tag] }
      end

      hash
    end

  end
end
