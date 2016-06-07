require 'photofs/fuse/tag_dir'

module PhotoFS::Fuse
  class TagDirRoot < PhotoFS::Fuse::TagDir
    # Represents tag directory at the top level of a tag
    # directory tree. It will include other tag dirs as
    # children.

    def add(name, node)
      raise Errno::EPERM
    end

    def mkdir(tag_name)
      tag = PhotoFS::Core::Tag.new tag_name

      raise Errno::EEXIST.new(tag_name) if tags.include?(tag)

      tags.add? tag
    end

    def rmdir(tag_name)
      tag = tags.find_by_name tag_name

      raise Errno::ENOENT.new(tag_name) unless tag
      raise Errno::EPERM unless tag.images.empty?

      tags.delete tag
    end

    def soft_move(node, name)
      raise Errno::EPERM
    end

    protected

    def additional_files
      { 'stats' => stats_file }
    end

    def dir_tags
      tags.all
    end

    def stats_file
      # only toplevel: StatsFile.new 'stats', :tags => tags
      StatsFile.new 'stats', :tags => tags.limit_to_images(images_domain)
    end

    def images
      PhotoFS::Core::ImageSet.new
    end

  end
end
