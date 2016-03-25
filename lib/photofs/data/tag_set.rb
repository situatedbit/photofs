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
        return nil if @record_object_map.has_key?(tag.name) || Tag.find_by_simple_object(tag)
        
        record = Tag.new_from_tag tag

        record.save!

        @record_object_map[record] = tag
      end

      def delete(tag)
        record = Tag.new_from_tag(tag)

        @record_object_map.delete record

        record.destroy
      end

      def save!
        save_record_object_map(@record_object_map)
      end

      protected

      def tags
        @record_object_map = load_all_records(@record_object_map, Tag)

        @record_object_map
      end

    end
  end
end
