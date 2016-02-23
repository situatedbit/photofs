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

      def separator
        ::File::SEPARATOR
      end

      def stat(path)
        ::File.stat path
      end

    end
  end
end



