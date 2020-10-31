module PhotoFS
  module Core
    module ImageName
      # There are two types of names: irregular and normalized.
      # Normalized names take the form of a roll/collection date prefix, an
      # frame number, optional notes, and file extensions:
      #
      # 2019-07-04a-001-scan-2400dpi.tiff.jpg
      #
      # prefix: 2019-07-04a
      # frame: 001
      # notes: -scan-2400dpi
      # extensions: .tiff.jpg
      #
      # Irregular file names are everything else. Their frame number is the
      # last digits in the part of the name before the extension (or the entire
      # name before the extension if it does not end in digits), and extensions.
      # Hyphenated notes are not supported in this name format. For example:
      #
      # IMG_1234.color.xcf
      # frame: 1234
      # extensions: .color.xcf

      def ImageName.extensions(path)
        match = /^\.?[^.]+(\..+)/.match(::File.basename(path))

        match ? match[1] : ''
      end

      def ImageName.basename(path)
        ::File.basename(path, extensions(path))
      end

      def ImageName.frame(path)
        name = basename(path)
        #                        normalized name                  | irregular name
        match = name.match /(?:^\d{4}-\d{1,2}-\d{1,2}[a-z]*-(\d+))|(\d+)/

        # if no match, reference id is basename. If match, it's either normalized or irregular
        match.nil? ? name : (match[1] || match[2])
      end

      # Given a possible prefix, will return the leading portion that
      # matches the normalized prefix form. Will return empty string if
      # beginning of possible prefix does not match the normalized form.
      def ImageName.normalized_prefix(possible_prefix)
        match = possible_prefix.match(/^\d{4}-\d{1,2}-\d{1,2}[a-z]*/)

        match ? match[0] : ''
      end

      # Extracts the hyphenated notes portion of normalized and irregular paths
      def ImageName.notes(path)
          name = basename(path)
          normalized_name_matcher = /(?:^\d{4}-\d{1,2}-\d{1,2}[a-z]*-\d+)((?:-[\w]+)+)?/
          irregular_name_matcher = /(?:\d+)((?:-[\w]+)+)/

          normalized_match = name.match normalized_name_matcher

          if normalized_match
            normalized_match[1] || ''
          else
            irregular_match = name.match irregular_name_matcher
            irregular_match.nil? ? '' : irregular_match[1]
          end
      end

      def ImageName.prefix(path)
        normalized_prefix basename(path)
      end

      # The prefix and frame
      # e.g., a/b/2019-12-12a-004-scan.jpg -> 2019-12-12a-004
      def ImageName.reference_name(path)
        # Only include prefix if it's in normalized form (i.e., prefix() returns non-empty string)
        [prefix(path), frame(path)].reject { |c| c.empty? }.join('-')
      end

      # the path of the image's parent directory combined with the prefix and frame
      # e.g., a/b/2019-12-12a-004-scan.jpg -> a/b/2019-12-12a-004
      def ImageName.reference_path(path)
        ::File.join [::File.dirname(path), reference_name(path)]
      end
    end
  end
end
