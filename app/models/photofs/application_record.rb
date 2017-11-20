require 'active_record'

module PhotoFS
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
