module PhotoFS
  module Core
    module ImageName
      # Ideally filenames are normalized. Normalized names take the form of a
      # roll/collection date prefix, an frame number, optional notes, and
      # file extensions:
      #
      # 2019-07-04a-001-scan-2400dpi.tiff.jpg
      #
      # prefix: 2019-07-04a
      # frame: 001
      # notes: -scan-2400dpi
      # extensions: .tiff.jpg
      #
      # For other well-known forms of names, we can extract a frame from the
      # digits in the file name, while still supporting notes:
      #
      # Fuji        DSC2349-mono-cropped.JPG
      # Canon       IMG_2343.JPG
      # open camera IMG_20201019_124528.JPG
      # signal      signal-2010-03-23-098234.jpg
      #
      # For names that start with indexes we can interpret as frame numbers:
      #
      # 01.tiff
      # 02-mono.tiff
      #
      # For all others, the frame is the entire basename:
      #
      # diane-arbus-03-medium.webp
      #
      # With a normalized prefix and frame, we can establish a reference name
      # for each image that allows us to group them with derivitive images:
      #
      # reference name: a/b/2019-12-12a-004-scan.jpg -> 2019-12-12a-004
      #
      # Names that lack normalized prefixes will only include the frame
      # in the reference name. This can lead to collisions, since
      # IMG_1234 and DSC1234 would have the same reference name.

      # Given a possible prefix, will return the leading portion that
      # matches the normalized prefix form. Will return empty string if
      # beginning of possible prefix does not match the normalized form.
      def ImageName.normalized_prefix(possible_prefix)
        match = possible_prefix.match(/\A\d{4}-\d{1,2}-\d{1,2}[a-z]*/)

        match ? match[0] : ''
      end

      # Returns 0 or more file extensions seperated by dots. Assumes names
      # with leading dots are hidden files.
      def ImageName.extensions(path)
        match = /\A\.?[^.]+(\..+)/.match(::File.basename(path))

        match ? match[1] : ''
      end

      def ImageName.basename(path)
        ::File.basename(path, extensions(path))
      end

      module Common
        # path of the image's parent directory combined with the reference name
        def reference_path
          ::File.join [::File.dirname(@path), reference_name]
        end
      end

      # Factory method. Match the path to the most appropriate kind of supported
      # name, and return an instance of the parsed name object.
      def ImageName.parse(path)
        # IrregularName is returned by default, since it's match function is true.
        [NormalizedName, IndexedName, IrregularName].select { |name| name.matches(path) }.first.new(path)
      end

      class NormalizedName
        include Common

        def self.expression
          /(?<prefix>^\d{4}-\d{1,2}-\d{1,2}[a-z]*)-(?<frame>\d+)(?<notes>(?:-+\w+)*)?/
        end

        def self.matches(path)
          ImageName.basename(path).match(self.expression)
        end

        def initialize(path)
          @path = path
          @match = ImageName.basename(path).match(NormalizedName.expression)
        end

        def frame
          @match['frame']
        end

        def notes
          @match['notes'] || ''
        end

        def prefix
          @match['prefix']
        end

        def reference_name
          "#{prefix}-#{frame}"
        end
      end

      class IndexedName
        # Fuji        DSC1234
        # Canon       IMG_1234
        # open camera IMG_20201019_124528
        # open camera IMG_20201019_124528_1 (second image taken at 12:45:28 on 2020-10-19)
        # signal      signal-2010-03-23-098234
        # signal      signal-2010-03-23-098234-1
        # indexed     03.tiff or 03-mono.tiff

        include Common

        def self.expression
          /\A[a-z]*(?<frame>(?:[-_]?\d+)+\b)(?<notes>(?:-+\w+)*)?/i
        end

        def self.matches(path)
          ImageName.basename(path).match(self.expression)
        end

        def initialize(path)
          @path = path
          @match = ImageName.basename(path).match(IndexedName.expression)
        end

        def frame
          @match['frame'].gsub(/[-_]/, '')
        end

        def notes
          @match['notes'] || ''
        end

        def prefix
          ''
        end

        def reference_name
          frame
        end
      end

      class IrregularName
        # Catch-all for everything else. Treat the entire basename as the frame.

        include Common

        def self.matches(path)
          true
        end

        def initialize(path)
          @path = path
        end

        def frame
          ImageName.basename @path
        end

        def notes
          ''
        end

        def prefix
          ''
        end

        def reference_name
          frame
        end
      end

    end
  end
end
