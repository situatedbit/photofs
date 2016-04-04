require 'photofs/fs'

module PhotoFS
  module Data
    module Lock

      def self.included(base)
        base.extend ClassMethods
      end

      def _locked_send(method_name, *args, &block)
        PhotoFS::FS.file_system.lock(@_lock_path) do
          log "calling #{method_name.to_s}"

          return send method_name, *args, &block
        end
      end

      def set_lock_path(path)
        @_lock_path = path
      end

      module ClassMethods
        def wrap_with_lock(*methods)
          methods.each do |method|
            original_method_name = method.to_sym
            lock_wrap_method_name = "_lock_wrap_#{method.to_s}".to_sym

            alias_method lock_wrap_method_name, original_method_name

            define_method(original_method_name) do |*args, &block|
              _locked_send lock_wrap_method_name, *args, &block
            end
          end # each method
        end

      end # ClassMethods
    end
  end
end
