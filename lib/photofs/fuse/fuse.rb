require 'photofs/core/image'
require 'photofs/data/database'
require 'photofs/data/image_set'
require 'photofs/data/lock'
require 'photofs/data/tag_set'
require 'photofs/fs'
require 'photofs/fuse/file_monitor'
require 'photofs/fuse/mirrored_dir'
require 'photofs/fuse/relative_path'
require 'photofs/fuse/root_dir'
require 'photofs/fuse/search_cache'
require 'photofs/fuse/tag_dir'
require 'rfuse'

module PhotoFS
  module Fuse
    class Fuse
      include PhotoFS::Data::Lock
      include PhotoFS::Data::Database::WriteCounter

      def self.fs
        PhotoFS::FS.file_system
      end

      def initialize(options)
        raise RFuse::Error, "Missing source option (-o source=path)" unless options[:source]

        @source_path = options[:source]
        @mountpoint = options[:mountpoint]
        @environment = options[:env] || 'production'
        @node_cache = {}

        @images = PhotoFS::Data::ImageSet.new() # global image set
        @tags = PhotoFS::Data::TagSet.new
        @search_cache = SearchCache.new

        @root = RootDir.new

        PhotoFS::FS.data_path_parent = @source_path
      end

      def init(context, rfuse_connection_info)
        initialize_database unless @environment == 'test'

        scan_source_path

        @root.add MirroredDir.new('o', @source_path, {:tags => @tags, :images => @images})
        @root.add TagDir.new('t', @tags, {:images => @images})
        @root.add File.new('.photofs-data-parent', @source_path)

        log "Mounted at #{@source_path}"
      end

      private

      def initialize_database
        db = PhotoFS::Data::Database.new(@environment, PhotoFS::FS.data_path)

        db.connect.ensure_schema
      end

      def search_cache
        cache_counter = database_write_counter

        unless @search_cache.valid? cache_counter
          @search_cache.invalidate cache_counter
        end

        @search_cache
      end

      def save!
        @images.save!
        @tags.save!

        @search_cache.invalidate increment_database_write_counter
      end

      def scan_source_path
        log "Scanning files under #{@source_path}"

        FileMonitor.new(@source_path).paths.each do |path|
          @images.add PhotoFS::Core::Image.new(path) unless @images.find_by_path(path)
        end

        log "Scanning complete"
      end

      def search(path)
        node = search_cache.fetch(path.to_s) { @root.search(path) }

        raise Errno::ENOENT.new(path.to_s) if node.nil?

        node
      end

      public
      def readdir(context, path, filler, offset, ffi)
        log "readdir: #{path}"

        dir = search RelativePath.new(path)

        raise Errno::ENOTDIR.new(path) unless dir.directory?

        dir.nodes.each_pair { |name, node| filler.push(name, node.stat, 0) }
      end

      def rename(context, from, to)
        log "rename #{from} to #{to}"

        from = RelativePath.new from
        to = RelativePath.new to

        search(from.parent).rename(from.name, search(to.parent), to.name)

        save!
      end

      def getattr(context, path)
        log "stat: #{path}"

        path = RelativePath.new(path)

        Stat.new({:gid => context.gid, :uid => context.uid}, search(path).stat)
      end

      def readlink(context, path, size)
        log "readlink: #{path}, #{size.to_s}"

        search(RelativePath.new(path)).target_path
      end

      def mkdir(context, path, mode)
        log "mkdir: #{path}"

        path = RelativePath.new(path)

        search(path.parent).mkdir(path.name)

        save!
      end

      def rmdir(context, path)
        log "rmdir: #{path}"

        path = RelativePath.new(path)

        search(path.parent).rmdir(path.name)

        save!
      end

      def symlink(context, link_target, as)
        log "symlink: #{as} => #{link_target}"

        image = @images.find_by_path(link_target)

        raise Errno::EPERM unless image

        path = RelativePath.new(as)

        search(path.parent).symlink(image, path.name)

        save!
      end

      def log(s)
        puts s
      end

      def unlink(context, path)
        log "unlink: #{path}"

        path = RelativePath.new(path)

        search(path.parent).remove(path.name)

        save!
      end

      wrap_with_lock :scan_source_path, :readdir, :rename, :getattr, :readlink, :mkdir, :rmdir, :symlink, :unlink
    end
  end
end # module
