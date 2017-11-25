require 'benchmark'

# Usage:
# include Profile
#
# profile 'name-of-your-section' do
#   ... code to profile ...
# end
#
# on EXIT:
# PhotoFS::Support::Profiler.report
module PhotoFS
  module Support
    module Profiler
      @@metrics = {}

      def self.add_measurement(label, measurement)
        if @@metrics.has_key? label
          @@metrics[label].add_metric(measurement)
        else
          @@metrics[label] = ProfiledSnippet.new(label, measurement)
        end
      end

      def self.report

        @@metrics.values.sort.each do |metric|
          metric.report
        end
      end

      class ProfiledSnippet
        include Comparable

        def initialize(label, initial_measurement)
          @label = label
          @measurements = initial_measurement
          @calls = 1
        end

        def <=>(other)
          to_s <=> other.to_s
        end

        def add_metric(measurement)
          @calls += 1

          @measurements = @measurements + measurement
        end

        def measurement_report
          @measurements.format "%t %r"
        end

        def average_real_time
          @measurements.real / @calls
        end

        def report
          # Name                       Times Called, Average Time per, Call Total Time
          puts sprintf("#{@label}      #{@calls}     avg: %#g    sum: #{measurement_report}\n", average_real_time)
        end

        def to_s
          @label
        end
      end

      def profile(label = '')
        block_return = nil
        raised_exception = nil

        measurement = Benchmark.measure do
          begin
            block_return = yield
          rescue => e
            raised_exception = e
          end
        end

        PhotoFS::Support::Profiler.add_measurement label, measurement

        raise raised_exception unless raised_exception.nil?

        block_return
      end

    end
  end
end
