require 'photofs/fuse/tag_dir_root'

module PhotoFS::Fuse
  class TagDirTopLevel < PhotoFS::Fuse::TagDirRoot
    # Class to represent the tag dir at the top level of the entire
    # file system. The special knowledge here is that tags include
    # all tags in the system. We can optimize around that, hence the
    # subclass.

    protected

    def stats_file
      StatsFile.new 'stats', :tags => tags
    end

  end
end
