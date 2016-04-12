require 'benchmark'

module PhotoFS
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
      @@metrics.values.each do |metric|
        metric.report
      end
    end

    class ProfiledSnippet
      def initialize(label, initial_measurement)
        @label = label
        @measurements = initial_measurement
        @calls = 1
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
        puts sprintf("#{@label}      #{@calls}     %#g     #{measurement_report}\n", average_real_time)
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

      PhotoFS::Profiler.add_measurement label, measurement

      raise raised_exception unless raised_exception.nil?

      block_return
    end

  end
end

=begin
  profile :method_name, 'optional-name'

Name              Times Called        Total Time        Average Time per Call
=end
