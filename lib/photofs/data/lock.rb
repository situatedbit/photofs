require 'photofs/fs'

module PhotoFS
  module Data
    module Lock

      def self.included(base)
        base.extend ClassMethods
      end

      def data_lock
        PhotoFS::FS.file_system.lock(PhotoFS::FS.data_path_join('photofs.lock')) do
          yield
        end
      end

      module ClassMethods
        def wrap_with_data_lock(*methods)
          methods.each do |method|
            original_method_name = method.to_sym
            lock_wrap_method_name = "_lock_wrap_#{method.to_s}".to_sym

            alias_method lock_wrap_method_name, original_method_name

            # overwrite the original method with a new method that wraps a
            # call back to the original method, but within a lock block.
            define_method(original_method_name) do |*args, &block|
              data_lock { return send lock_wrap_method_name, *args, &block }
            end
          end # each method
        end

      end # ClassMethods
    end
  end
end
