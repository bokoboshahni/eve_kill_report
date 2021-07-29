require 'time'

module EVEKillReport
  class Pipeline
    module Transforms
      class KillmailSummaries
        def initialize(options = {})
          @logger = options[:logger]
        end

        def process(killmail)
          killmail_id = killmail['killmail_id']
          killmail_hash = killmail['zkb']['hash']
          killmail.replace(
            id: killmail_id,
            hash: killmail_hash,
            date: DateTime.parse(killmail['killmail_time']).to_date,
            ship: killmail['ship'][:typename],
            alliance: killmail['alliance']['name'],
            corporation: killmail['corporation']['name'],
            region: killmail['region'][:itemname],
            constellation: killmail['constellation'][:itemname],
            solar_system: killmail['solar_system'][:itemname],
            url: "https://esi.evetech.net/latest/killmails/#{killmail_id}/#{killmail_hash}/"
          )
        end

        private

        attr_reader :logger
      end
    end
  end
end