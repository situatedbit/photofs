require 'photofs/fuse/node'
require 'photofs/fuse/stat'

module PhotoFS::Fuse
  class StatsFile < PhotoFS::Fuse::Node
    def initialize(name, options = {})
      @tags = options[:tags]

      super name, options
    end

    def contents
      @contents ||= @tags.all.sort_by { |t| t.name }.reduce('') do |contents, tag|
        file_list = tag.images.map { |i| i.basename }.sort.join ', '

        "#{contents}\n#{tag.name}: #{file_list}"
      end
    end

    def read_contents(size, offset)
      contents[offset..offset + size - 1] || ''
    end

    def stat
      @stat ||= RFuse::Stat.file(Stat::MODE_READ_ONLY, { :size => contents.length })
    end
  end
end


