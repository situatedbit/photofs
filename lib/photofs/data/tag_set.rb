require 'photofs/data/repository'
require 'photofs/core/tag_set'
require 'photofs/data/tag'

module PhotoFS
  module Data
    class TagSet < PhotoFS::Core::TagSet
      include Repository

      def initialize
        @record_object_map = {} # maps Data::Tag => Core::Tag

        super
      end

      def add?(tag)
# consider being smarter about this by querying the database instead of using the cache binding
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

      def save!
        save_record_object_map(@record_object_map)
      end

      protected

      def tags
        load_all_records(@record_object_map, Tag)

        @record_object_map.values
      end

    end
  end
end
