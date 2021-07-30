require 'active_support/core_ext/class/attribute'
require 'oj'
require 'retriable'

require 'eve_kill_report/esi_helper'

module EVEKillReport
  class Pipeline
    module Transforms
      class KillmailCorporations
        include ESIHelper

        def initialize(options = {})
          @user_agent = options[:user_agent]
          @logger = options[:logger]
          @options = options
        end

        def process(killmail)
          Retriable.retriable on: [Oj::ParseError] do
            begin
              corporation_id = killmail['victim']['corporation_id']
              if corporations.key?(corporation_id)
                killmail.merge!('corporation' => corporations[corporation_id])
              else
                url = "https://esi.evetech.net/latest/corporations/#{corporation_id}/"
                logger.debug("Fetching corporation from ESI: #{url}")
                response = esi.get(url)
                corporation = Oj.load(response.body)
                corporations[corporation_id] = corporation
                killmail.merge!('corporation' => corporation)
              end
            rescue NoMethodError
              logger.error("Unknown corporation for killmail #{killmail['killmail_id']}. Check #{url}")
              killmail.merge!('corporation' => 'Unknown')
            end
          end
        end

        private

        attr_reader :user_agent, :logger, :options

        class_attribute :corporations, instance_reader: true
        self.corporations = {}
      end
    end
  end
end
