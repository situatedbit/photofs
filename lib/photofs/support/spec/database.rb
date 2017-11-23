require 'active_record'

module PhotoFS
  module Support
    module Spec
      module Database
        def connect_database
          environment = 'test'
          configurations = YAML::load(File.open('db/config.yml'))
          ActiveRecord::Base.configurations = configurations
          ActiveRecord::Base.establish_connection(configurations[environment])
        end
      end
    end
  end
end
