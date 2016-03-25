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
        return nil if Tag.from_tag tag
        
        new_record = Tag.new_from_tag tag

        new_record.save!

        @record_object_map[new_record] = tag
      end

      def delete(tag)
        record = Tag.from_tag tag

        @record_object_map.delete record

        record.destroy
      end

      def save!
        save_record_object_map(@record_object_map)
      end

      protected

      # returns name => tag object mapping
      #
      # side effect: loads all tag records into the record/object map
      def tags
        @record_object_map = load_all_records(@record_object_map, Tag)

        tags_map = {}

        @record_object_map.each { |record, tag| tags_map[tag.name] = tag }

        tags_map
      end

    end
  end
end
