require 'application_record'

module PhotoFS
  class TagBinding < ApplicationRecord
    belongs_to :tag
    belongs_to :image
  end
end
