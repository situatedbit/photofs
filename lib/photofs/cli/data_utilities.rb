require 'photofs/core/tag'

module PhotoFS
  module CLI
    module DataUtilities
      def tag_images(tag_set, tag_name, images)
        tag = tag_set.find_by_name(tag_name) || tag_set.add?(PhotoFS::Core::Tag.new tag_name)

        tag.add_images images
      end

      def untag_images(tag_set, tag_name, images)
        tag = tag_set.find_by_name tag_name

        tag.remove(images) if tag
      end

    end
  end
end
