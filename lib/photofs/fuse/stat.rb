require 'rfuse'

module PhotoFS
  module Fuse
    class Stat < RFuse::Stat
      MODE_READ_ONLY = 0000444
      MODE_MASK = 0000777

      PERM_USER_WRITE = 0000200

      # list of attributes included in RFuse::Stat helper class
      STAT_ATTRIBUTES = [ :atime, :blksize, :blocks, :ctime, :dev, 
                          :gid, :ino, :mode, :mtime, :nlink, :rdev, 
                          :size, :uid ]

      # returns hash of attributes for either File::Stat or RFuse::Stat
      def self.stat_hash(stat)
        attr_hash = {}

        STAT_ATTRIBUTES.map do | attribute |
          attr_hash[attribute] = stat.send attribute
        end

        return attr_hash
      end

      def self.add(mode, permission)
        mode | permission
      end

      # assumes :mode is set in either base_stat or attributes
      def initialize(attributes, base_stat=nil)
        attributes = base_stat ? Stat.stat_hash(base_stat).merge(attributes) : attributes

        type = S_IFMT & attributes[:mode]
        permissions = MODE_MASK & attributes[:mode]

        super(type, permissions, attributes)
      end
    end
  end
end
