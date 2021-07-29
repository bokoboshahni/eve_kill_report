require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/integer/time'
require 'csv'

module EVEKillReport
  class Pipeline
    module Destinations
      class CommaSeparated
        def initialize(options = {})
          @output_file = options[:output]
          @options = options
          @logger = options['logger']
        end

        def write(killmail)
          unless headers_written
            csv << killmail.keys
            @headers_written = true
          end

          yesterday = (Time.now.utc - 1.day).to_date
          return if options['yesterday'] && killmail[:date] != yesterday

          return if options['region'] && options['region'].exclude?(killmail[:region])

          csv << killmail.values
        end

        def close
          csv.close
        end

        private

        attr_reader :headers_written, :output_file, :options, :logger

        def csv
          @csv ||= CSV.open(output_file, 'w')
        end
      end
    end
  end
end
