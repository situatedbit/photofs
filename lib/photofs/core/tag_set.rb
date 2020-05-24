require 'forwardable'
require 'photofs/core/tag'

module PhotoFS
  module Core
    class TagSet
      extend Forwardable
      include Enumerable

      # returns image set
      def self.intersection(tags)
        tags = [tags].flatten # normalize to array

        if tags.nil? || tags.empty?
          ImageSet.new
        elsif tags.length == 1
          ImageSet.new(set: tags.first)
        else
          tags.first & tags[1..-1]
        end
      end

      def initialize
        @tags = {}
      end

      def add?(tag)
        if tags.has_key?(tag.name)
          nil
        else
          tags[tag.name] = tag
          self
        end
      end

      def all
        tags.values
      end

      def delete(tag)
        tags.delete tag.name
      end

      # implement Enumerable
      def each(&block)
        tags.values.each &block
      end

      # returns array if tag_names is an array, a single tag otherwise
      def find_by_name(tag_names)
        if tag_names.respond_to? :map
          tag_names.map { |n| tags[n] }.select { |t| not t.nil? }
        else
          tags[tag_names]
        end
      end

      # returns array of tags which tag any of the images
      def find_by_images(image_set)
        hash = image_tags_hash

        image_set.map { |image| hash[image] || [] }.flatten.uniq
      end

      def rename(old_tag, new_tag)
        old_tag.images.each { |image| new_tag.add image }

        add? new_tag

        delete old_tag
      end

      def to_s
        "[#{tags.values.join(', ')}]"
      end

      # a new tag set limited only to tags and images from image_set
      def limit_to_images(image_set)
        find_by_images(image_set).reduce(TagSet.new) do |new_set, tag|
          new_set.add?(Tag.new tag.name, { set: (image_set & tag) })
        end
      end

      protected

      def tags
        @tags
      end

      private

      def image_tags_hash
        hash = {}

        tags.values.each do |tag|
          tag.images.each { |i| hash[i] = hash.fetch(i, []) + [tag] }
        end

        hash
      end

      def_delegators :tags, :size, :size
      def_delegators :tags, :empty?, :empty?
      def_delegators :tags, :has_value?, :include?
    end
  end
end
