module EVEKillReport
  class Pipeline
    module Transforms
      class KillmailLocations
        def initialize(options = {})
          @static_data = options[:static_data]
          @logger = options[:logger]
        end

        def process(killmail)
          solar_system = static_data.solar_system(killmail['solar_system_id'])
          constellation = static_data.constellation(solar_system[:constellationid])
          region = static_data.region(constellation[:regionid])

          killmail.merge!(
            'solar_system' => solar_system,
            'constellation' => constellation,
            'region' => region
          )
        end

        private

        attr_reader :static_data, :logger
      end
    end
  end
end
