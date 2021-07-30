require 'eve_kill_report/esi_helper'

module EVEKillReport
  class Pipeline
    module Transforms
      class KillmailAttackers
        include ESIHelper

        def initialize(options = {})
          @static_data = options[:static_data]
          @logger = options[:logger]
          @user_agent = options[:user_agent]
          @options = options
        end

        def process(killmail)
          top_attacker = killmail['attackers'].max_by { |a| a['damage_done'] }
          top_attacker_ship_type = static_data.type(top_attacker['ship_type_id'])
          top_attacker_alliance = alliance(top_attacker['alliance_id'])
          top_attacker_corporation = corporation(top_attacker['corporation_id'])
          attacker_count = killmail['attackers'].count

          killmail.merge!(
            'top_attacker' => top_attacker,
            'top_attacker_ship_type' => top_attacker_ship_type,
            'top_attacker_alliance' => top_attacker_alliance,
            'top_attacker_corporation' => top_attacker_corporation
          )
        rescue NoMethodError
          logger.error("Unknown ship type for top attacker in killmail #{killmail['killmail_id']}")
          killmail.merge!('top_attacker_ship_type' => { typename: 'Unknown' })
        end

        private

        attr_reader :static_data, :logger, :user_agent, :options

        class_attribute :corporations, instance_reader: true
        self.corporations = {}

        class_attribute :alliances, instance_reader: true
        self.alliances = {}

        def corporation(corporation_id)
          Retriable.retriable on: [Oj::ParseError] do
            begin
              if corporations.key?(corporation_id)
                return corporations[corporation_id]
              else
                url = "https://esi.evetech.net/latest/corporations/#{corporation_id}/"
                logger.debug("Fetching corporation from ESI: #{url}")
                response = esi.get(url)
                corporation = Oj.load(response.body)
                corporations[corporation_id] = corporation
                return corporation
              end
            rescue NoMethodError
              logger.error("Unknown attacker corporation for killmail #{killmail['killmail_id']}. Check #{url}")
            end
          end
        end

        def alliance(alliance_id)
          Retriable.retriable on: [Oj::ParseError], tries: 10 do
            begin
              if alliances.key?(alliance_id)
                return alliances[alliance_id]
              else
                url = "https://esi.evetech.net/latest/alliances/#{alliance_id}/"
                logger.debug("Fetching alliance from ESI: #{url}")
                response = esi.get(url)
                alliance = Oj.load(response.body)
                alliances[alliance_id] = alliance
                return alliance
              end
            rescue NoMethodError
              logger.error("Unknown attacker alliance for killmail #{killmail['killmail_id']}. Check #{url}")
            end
          end
        end
      end
    end
  end
end
