require 'eve_kill_report/esi_helper'
require 'retriable'

module EVEKillReport
  class Pipeline
    module Transforms
      class ESIKillmails
        include ESIHelper

        def initialize(options = {})
          @user_agent = options[:user_agent]
          @logger = options[:logger]
        end

        def process(killmail)
          Retriable.retriable on: [JSON::ParserError] do
            killmail_id = killmail['killmail_id']
            killmail_hash = killmail['zkb']['hash']
            url = "https://esi.evetech.net/latest/killmails/#{killmail_id}/#{killmail_hash}/"
            logger.debug("Fetching killmail from ESI: #{url}")
            response = esi.get(url)
            killmail.merge!(JSON.parse(response.body))
          end
        end

        private

        attr_reader :user_agent, :logger
      end
    end
  end
end
