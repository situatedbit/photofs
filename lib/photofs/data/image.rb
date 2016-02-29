require 'active_record'

module PhotoFS
  module Data
    class Image < ActiveRecord::Base
      belongs_to :jpeg_file, { :class_name => 'File' }

      validates :jpeg_file, presence: true
      validates :jpeg_file_id, uniqueness: true
    end
  end
end
