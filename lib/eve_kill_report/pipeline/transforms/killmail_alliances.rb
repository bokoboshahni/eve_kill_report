require 'active_support/core_ext/class/attribute'
require 'retriable'

require 'eve_kill_report/esi_helper'

module EVEKillReport
  class Pipeline
    module Transforms
      class KillmailAlliances
        include ESIHelper

        def initialize(options = {})
          @user_agent = options[:user_agent]
          @logger = options[:logger]
        end

        def process(killmail)
          Retriable.retriable on: [JSON::ParserError], tries: 10 do
            begin
              alliance_id = killmail['victim']['alliance_id']
              if alliances.key?(alliance_id)
                killmail.merge!('alliance' => alliances[alliance_id])
              else
                url = "https://esi.evetech.net/latest/alliances/#{alliance_id}/"
                logger.debug("Fetching alliance from ESI: #{url}")
                response = esi.get(url)
                alliance = JSON.parse(response.body)
                alliances[alliance_id] = alliance
                killmail.merge!('alliance' => alliance)
              end
            rescue NoMethodError
              logger.error("Unknown alliance for killmail #{killmail['killmail_id']}")
              killmail.merge!('alliance' => 'Unknown')
            end
          end
        end

        private

        attr_reader :user_agent, :logger

        class_attribute :alliances, instance_reader: true
        self.alliances = {}
      end
    end
  end
end
