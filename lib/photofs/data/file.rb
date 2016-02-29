require 'active_record'

module PhotoFS
  module Data
    class File < ActiveRecord::Base
      validates :path, presence: true
      validates :path, uniqueness: true
    end
  end
end
