require 'photofs/core/image'
require 'photofs/data/database'
require 'photofs/data/image_set'
require 'photofs/data/synchronize'
require 'photofs/data/tag_set'
require 'photofs/fs'
require 'photofs/fs/normalized_path'
require 'photofs/fs/relative_path'
require 'photofs/fuse/recently_tagged_dir_root'
require 'photofs/fuse/root_dir'
require 'photofs/fuse/mirrored_dir'
require 'photofs/fuse/search_cache'
require 'photofs/fuse/tag_dir_top_level'
require 'rfuse'

module PhotoFS
  module Fuse
    class Fuse
      include PhotoFS::Data::Synchronize

      def self.fs
        PhotoFS::FS.file_system
      end

      def initialize(options, config = {})
        raise RFuse::Error, "Missing source option (-o source=path)" unless options[:source]

        @option_log = options.has_key?(:log)
        @source_path = options[:source]
        @mountpoint = options[:mountpoint]
        @environment = options[:env] || 'production'
        @config = config

        @images = PhotoFS::Data::ImageSet.new() # global image set
        @tags = PhotoFS::Data::TagSet.new
        @search_cache = SearchCache.new

        @lock = PhotoFS::Data::Synchronize.write_lock
        @lock.register_on_detect_count_increment(Proc.new { |lock| on_datastore_cache_increment(lock) })
        @fuse_cache_counter = nil

        @root = RootDir.new

        PhotoFS::FS.data_path_parent = @source_path
      end

      def init(context, rfuse_connection_info)
        initialize_database

        @root.add MirroredDir.new('o', @source_path, {tags: @tags, images: @images})
        @root.add TagDirTopLevel.new('t', @tags, {images: @images})
        @root.add File.new('.photofs', PhotoFS::FS.data_path)
        @root.add RecentlyTaggedDirRoot.new('recent', @tags, @images, { config: @config })

        log "Config: #{@config}"
        log "Mounted at #{@source_path}"
      end

      private

      def initialize_database
        options = {
          app_root: PhotoFS::FS.app_root,
          config: PhotoFS::FS.data_config,
          db_dir: PhotoFS::FS.db_dir,
          migration_paths: PhotoFS::FS.migration_paths
        }

        PhotoFS::Data::Database::Connection.new(options).connect.ensure_schema
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

        file = search PhotoFS::FS::RelativePath.new(path)

        raise Errno::EACCES.new(path) if file.directory?

        file.read_contents(size, offset)
      end

      def readdir(context, path, filler, offset, ffi)
        log "readdir: #{path}"

        dir = search PhotoFS::FS::RelativePath.new(path)

        raise Errno::ENOTDIR.new(path) unless dir.directory?

        dir.nodes.each_pair { |name, node| filler.push(name, node.stat, 0) }
      end

      def rename(context, from, to)
        log "rename #{from} to #{to}"

        from = PhotoFS::FS::RelativePath.new from
        to = PhotoFS::FS::RelativePath.new to

        search(from.parent).rename(from.name, search(to.parent), to.name)

        save!
      end

      def getattr(context, path)
        log "stat: #{path}"

        path = PhotoFS::FS::RelativePath.new(path)

        Stat.new({gid: context.gid, uid: context.uid}, search(path).stat)
      end

      def readlink(context, path, size)
        log "readlink: #{path}, #{size.to_s}"

        search(PhotoFS::FS::RelativePath.new(path)).target_path
      end

      def mkdir(context, path, mode)
        log "mkdir: #{path}"

        path = PhotoFS::FS::RelativePath.new(path)

        search(path.parent).mkdir(path.name)

        save!
      end

      def rmdir(context, path)
        log "rmdir: #{path}"

        path = PhotoFS::FS::RelativePath.new(path)

        search(path.parent).rmdir(path.name)

        save!
      end

      def symlink(context, link_target, as)
        log "symlink: #{as} => #{link_target}"

        begin
          image = @images.find_by_path PhotoFS::FS::NormalizedPath.new(real: link_target, root: PhotoFS::FS::images_path).to_s
        rescue PhotoFS::FS::NormalizedPathException
          raise Errno::EPERM
        end

        raise Errno::EPERM unless image

        path = PhotoFS::FS::RelativePath.new(as)

        search(path.parent).symlink(image, path.name)

        save!
      end

      def log(s)
        @log ||= Logger.new(PhotoFS::FS.log_file)

        if @option_log
          @log.info(s)

          puts s
        end
      end

      def unlink(context, path)
        log "unlink: #{path}"

        path = PhotoFS::FS::RelativePath.new(path)

        search(path.parent).remove(path.name)

        save!
      end

      wrap_with_lock :write_lock, :rename, :mkdir, :rmdir, :symlink, :unlink
      wrap_with_count_check :write_lock, :read, :readdir, :getattr, :readlink
    end
  end
end # module
