require 'photofs/core/tag_set'
require 'photofs/data/tag'

module PhotoFS
  module Data
    class TagSet < PhotoFS::Core::TagSet

      def initialize
        @record_object_map = {} # maps Data::Tag => Core::Tag

        super
      end

      def add?(tag)
        if tags.has_key?(tag.name)
          nil
        else
          tags[tag.name] = tag
          self
        end
      end

      def delete(tag)
        # find in records, remove via Tags
      end

      protected

      def tags
        # must return all tag simple objects
        Tags.all
      end

    end
  end
end
