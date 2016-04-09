require 'photofs/fs'

module PhotoFS
  module Data
    module Synchronize
      READ_WRITE_LOCK_FILE = 'photofs.lock'

      def self.read_write_lock
        @@lock ||= Lock.new(READ_WRITE_LOCK_FILE)
      end

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def wrap_with_lock(lock, *methods)
          methods.each do |method|
            original_method_name = method.to_sym
            lock_wrap_method_name = "_with_lock_#{method.to_s}".to_sym

            alias_method lock_wrap_method_name, original_method_name

            # overwrite the original method with a new method that wraps a
            # call back to the original method, but within a lock block.
            define_method(original_method_name) do |*args, &block|
              lock.grab { return send lock_wrap_method_name, *args, &block }
            end
          end # each method
        end
      end # ClassMethods

      class Lock
        INITIAL_COUNT_VALUE = 0

        def initialize(lock_file)
          @lock_file = lock_file
          @previous_count = nil
          @detect_count_increment_callbacks = []
        end

        def count
          PhotoFS::FS.file_system.write_file(count_file, INITIAL_COUNT_VALUE.to_s) unless PhotoFS::FS.file_system.exist?(count_file)

          contents = PhotoFS::FS.file_system.read_file(count_file)

          (contents.nil? || contents.empty?) ? INITIAL_COUNT_VALUE : Integer(contents)
        end

        def grab
          PhotoFS::FS.file_system.lock(lock_file) do
            new_count = count

            detected_count_increment if @previous_count != new_count

            @previous_count = new_count

            yield self
          end
        end

        def increment_count
          new_count = count + 1

          PhotoFS::FS.file_system.write_file(count_file, new_count.to_s)

          new_count
        end

        def register_on_detect_count_increment(callback)
          @detect_count_increment_callbacks << callback
        end

        private

        def lock_file
          # built on the fly to avoid early dependencies on setting the data path
          PhotoFS::FS.data_path_join(@lock_file)
        end

        def detected_count_increment
          @detect_count_increment_callbacks.each { |callback| callback.call self }
        end

        def count_file
          "#{lock_file}.count"
        end
      end # Lock

      # For use in tests
      class TestLock < Lock
        attr_reader :count

        def initialize
          @count = 0

          super 'test'
        end

        def grab
          yield self
        end

        def increment_count
          @count += 1
        end
      end # TestLock

    end
  end
end
