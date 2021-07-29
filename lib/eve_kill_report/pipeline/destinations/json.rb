require 'json'

module EVEKillReport
  class Pipeline
    module Destinations
      class JSON
        def initialize(options = {})
          @filename = options[:filename]
        end

        def write(killmail)
        end

        def close
        end
      end
    end
  end
end
