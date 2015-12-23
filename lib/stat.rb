module PhotoFS
  class Stat
    MODE_READ_ONLY = 0000444
    MODE_MASK = 0000777

    # list of attributes included in RFuse::Stat helper class
    STAT_ATTRIBUTES = [ :atime, :blksize, :blocks, :ctime, :dev, 
                        :gid, :ino, :mode, :mtime, :nlink, :rdev, 
                        :size, :uid ]

    def self.stat_hash(file_stat)
      attr_hash = {}

      STAT_ATTRIBUTES.map do | attribute |
        attr_hash[attribute] = file_stat.send attribute
      end

      return attr_hash
    end

  end
end
