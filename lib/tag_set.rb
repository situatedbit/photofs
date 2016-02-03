require_relative 'tag'

module PhotoFS
  class TagSet

    # returns image set
    def self.intersection(tags)
      tags = [tags].flatten # normalize to array

      if tags.nil? || tags.empty?
        ImageSet.new
      elsif tags.length == 1
        ImageSet.new(:set => tags.first)
      else
        tags.first & tags[1..-1]
      end
    end

    def initialize
      @tags = {}
    end

    def add?(tag)
      if @tags.has_key?(tag.name)
        nil
      else
        @tags[tag.name] = tag
        self
      end
    end

    def all
      @tags.values
    end

    def delete(tag)
      @tags.delete tag.name
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

    def to_s
      "[#{@tags.values.join(', ')}]"
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
