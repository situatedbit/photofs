require 'photofs/fs'

module PhotoFS
  module Data
    module Synchronize
      WRITE_LOCK_FILE = 'photofs.lock'

      def self.write_lock
        @@_write_lock ||= Lock.new(WRITE_LOCK_FILE)
      end

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def wrap_with_lock(lock_name, *methods)
          methods.each do |method|
            original_method_name = method.to_sym
            lock_wrap_method_name = "_with_lock_#{method.to_s}".to_sym

            alias_method lock_wrap_method_name, original_method_name

            # overwrite the original method with a new method that wraps a
            # call back to the original method, but within a lock block.
            define_method(original_method_name) do |*args, &block|
              # defering the lock binding until runtime allows for stubbing in tests
              lock = PhotoFS::Data::Synchronize.send lock_name

              lock.grab { return send lock_wrap_method_name, *args, &block }
            end
          end # each method
        end

        def wrap_with_count_check(lock_name, *methods)
          methods.each do |method|
            original_method_name = method.to_sym
            count_check_method_name = "_with_count_check_#{method.to_s}".to_sym

            alias_method count_check_method_name, original_method_name

            define_method(original_method_name) do |*args, &block|
              lock = PhotoFS::Data::Synchronize.send lock_name

              lock.check_count_increment

              return send count_check_method_name, *args, &block
            end
          end # each method
        end # wrap_with_count_check
      end # ClassMethods

      class Lock
        include PhotoFS::FS::FileSystem

        INITIAL_COUNT_VALUE = 0

        def initialize(lock_file)
          @lock_file = lock_file
          @previous_count = nil
          @detect_count_increment_callbacks = []
        end

        def check_count_increment
            new_count = count

            detected_count_increment if @previous_count != new_count

            @previous_count = new_count
        end

        def count
          contents = file_system.exist?(count_file) ? file_system.read_file(count_file) : nil

          (contents.nil? || contents.empty?) ? INITIAL_COUNT_VALUE : Integer(contents)
        end

        def grab
          file_system.lock(lock_file) do
            initialize_count_file # only do this within lock to prevent ordering issues

            check_count_increment

            yield self
          end
        end

        def increment_count
          new_count = count + 1

          file_system.write_file(count_file, new_count.to_s)

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
          @count_file ||= "#{lock_file}.count"
        end

        def initialize_count_file
          file_system.write_file(count_file, INITIAL_COUNT_VALUE.to_s) unless file_system.exist?(count_file)
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
          check_count_increment

          yield self
        end

        def increment_count
          @count += 1
        end
      end # TestLock

    end
  end
end
