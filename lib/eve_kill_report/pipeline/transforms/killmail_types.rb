module EVEKillReport
  class Pipeline
    module Transforms
      class KillmailTypes
        def initialize(options = {})
          @static_data = options[:static_data]
          @logger = options[:logger]
        end

        def process(killmail)
          killmail.merge!('ship' => static_data.type(killmail['victim']['ship_type_id']))
        rescue NoMethodError
          logger.error("Unknown ship type for killmail #{killmail['killmail_id']}")
          killmail.merge!('ship' => { typename: 'Unknown' })
        end

        private

        attr_reader :static_data, :logger
      end
    end
  end
end
