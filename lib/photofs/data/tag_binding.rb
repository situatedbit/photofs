require 'active_record'

module PhotoFS
  module Data
    class TagBinding < ActiveRecord::Base
      belongs_to :tag
      belongs_to :image
    end
  end
end
