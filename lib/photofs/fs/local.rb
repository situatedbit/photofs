require 'timeout'

# Thin layer on File and Dir for access to local file system.
module PhotoFS
  module FS
    class Local
      def absolute_path(path)
        ::File.absolute_path path
      end

      def chdir(path)
        if block_given?
          ::Dir.chdir(path) do |path|
            yield path
          end
        else
          ::Dir.chdir(path)
        end
      end

      def directory?(path)
        ::File.directory? path
      end

      def dirname(file)
        ::File.dirname(file)
      end

      def entries(path)
        ::Dir.entries path
      end

      def expand_path(path)
        ::File.expand_path path
      end

      def exist?(path)
        ::File.exist? path
      end

      def lock(path)
        ::File.open(path, ::File::RDWR | ::File::CREAT, 0644) do |file|
          begin
            Timeout::timeout(1) { file.flock ::File::LOCK_EX } # unlocks when file is closed
          rescue
            raise Errno::ENOLCK
          end

          yield
        end
      end

      def fnm(option)
        {:casefold => ::File::FNM_CASEFOLD}[option]
      end

      def glob(pattern, flags=0)
        if block_given?
          ::Dir.glob(pattern, flags) do |filename|
            yield filename
          end
        else
          ::Dir.glob(pattern, flags)
        end
      end

      def join(*args)
        ::File.join(*args)
      end

      def mkdir(path, mode = 0777)
        ::Dir.mkdir(path, mode)
      end

      def read_file(path)
        ::File.open(path, 'r') { |file| file.read }
      end

      def separator
        ::File::SEPARATOR
      end

      def stat(path)
        ::File.stat path
      end

      def write_file(path, contents)
        ::File.open(path, 'w') { |file| file.write contents }
      end

    end
  end
end



