require 'json'
require 'photofs/core/image'
require 'photofs/core/image_set'
require 'photofs/core/tag_set'

module PhotoFS
  module CLI
    class TagJsonParser

      JSON_TAGS = 'tags'

      def parse(json_string)
        begin
          parsed_json = JSON.parse json_string
        rescue => e
          raise ParseException, e.message
        end

        raise(ParseException, 'JSON structure missing top-level tags entity') unless parsed_json.has_key?('tags')

        raise(ParseException, 'JSON structure missing top-level tags array') unless parsed_json['tags'].kind_of?(Array)

        parsed_json['tags'].reduce(PhotoFS::Core::TagSet.new) do |tag_set, tag_struct|
          raise(ParseException, 'tag is missing a name') unless tag_struct.has_key?('name') && tag_struct['name'].kind_of?(String)

          paths = tag_struct.has_key?('paths') && tag_struct['paths'].kind_of?(Array) ? tag_struct['paths'] : []

          ## Convert all path strings into images
          images = paths.select { |p| p.kind_of? String }.map { |p| PhotoFS::Core::Image.new p }

          tag_set.add? PhotoFS::Core::Tag.new(tag_struct['name'], { set: images.to_set })
        end
      end

      class ParseException < Exception
      end
    end
  end
end
