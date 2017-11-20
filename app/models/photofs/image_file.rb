require 'application_record'

module PhotoFS
  class ImageFile < ApplicationRecord
    validates :path, presence: true
    validates :path, uniqueness: true
  end
end
