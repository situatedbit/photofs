require 'photofs/core/image'
require 'photofs/data/database'
require 'photofs/data/image_set'
require 'photofs/data/synchronize'
require 'photofs/data/tag_set'
require 'photofs/fs'
require 'photofs/fuse/mirrored_dir'
require 'photofs/fuse/relative_path'
require 'photofs/fuse/root_dir'
require 'photofs/fuse/search_cache'
require 'photofs/fuse/tag_dir_root'
require 'rfuse'

module PhotoFS
  module Fuse
    class Fuse
      include PhotoFS::Data::Synchronize

      def self.fs
        PhotoFS::FS.file_system
      end

      def initialize(options)
        raise RFuse::Error, "Missing source option (-o source=path)" unless options[:source]

        @source_path = options[:source]
        @mountpoint = options[:mountpoint]
        @environment = options[:env] || 'production'

        @images = PhotoFS::Data::ImageSet.new() # global image set
        @tags = PhotoFS::Data::TagSet.new
        @search_cache = SearchCache.new

        @lock = PhotoFS::Data::Synchronize.read_write_lock
        @lock.register_on_detect_count_increment(Proc.new { |lock| on_datastore_cache_increment(lock) })
        @fuse_cache_counter = nil

        @root = RootDir.new

        PhotoFS::FS.data_path_parent = @source_path
      end

      def init(context, rfuse_connection_info)
        initialize_database

        @root.add MirroredDir.new('o', @source_path, {:tags => @tags, :images => @images})
        @root.add TagDirRoot.new('t', @tags, {:images => @images})
        @root.add File.new('.photofs', PhotoFS::FS.data_path)

        log "Mounted at #{@source_path}"
      end

      private

      def initialize_database
        PhotoFS::Data::Database::Connection.new(PhotoFS::FS.data_path).connect.ensure_schema
      end

      def on_datastore_cache_increment(lock)
        # called when the lock.grab detects that the datastore counter
        # has been incremented. examine the counter against our caches.
        cache_counter = lock.count

        unless @search_cache.valid? cache_counter
          @search_cache.invalidate cache_counter
          @root.clear_cache
        end

        if @fuse_cache_counter != cache_counter
          ActiveRecord::Base.connection.clear_query_cache
          @images.clear_cache
          @tags.clear_cache
        end
      end

      def save!
        @images.save!
        @tags.save!

        count = @lock.increment_count
        @search_cache.invalidate count

        # since the change was made within this Fuse module, keep fuse cache counter up to date with lock's
        @fuse_cache_counter = @lock.increment_count
      end

      def search(path)
        node = @search_cache.fetch(path.to_s) { @root.search(path) }

        raise Errno::ENOENT.new(path.to_s) if node.nil?

        node
      end

      public
      def read(context, path, size, offset, ffi)
        log "read: #{path}"

        file = search RelativePath.new(path)

        raise Errno::EACCES.new(path) if file.directory?

        file.read_contents(size, offset)
      end

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
        @log ||= Logger.new(PhotoFS::FS.log_file)

        @log.info(s)

        puts s
      end

      def unlink(context, path)
        log "unlink: #{path}"

        path = RelativePath.new(path)

        search(path.parent).remove(path.name)

        save!
      end

      wrap_with_lock :read_write_lock, :read, :readdir, :rename, :getattr, :readlink, :mkdir, :rmdir, :symlink, :unlink
    end
  end
end # module
