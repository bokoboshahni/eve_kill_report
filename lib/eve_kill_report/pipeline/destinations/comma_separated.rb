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
          @count = 0
          @yesterday = (Time.now.utc - 1.day).to_date
        end

        def write(killmail)
          unless headers_written
            csv << FIELDS
            @headers_written = true
          end

          killmail_id = killmail['killmail_id']
          killmail_hash = killmail['zkb']['hash']

          if killmail['killmail_time'].nil?
            logger.warn("Killmail #{killmail_id}/#{killmail_hash} has no date")
            killmail_date = ''
          else
            killmail_date = DateTime.parse(killmail['killmail_time']).to_date
          end

          if options['date'] && killmail_date != DateTime.parse(options['date']).to_date
            logger.debug("Skipping killmail #{killmail_id}. #{killmail_date} != #{options['date']}")
            return
          elsif options['yesterday'] && killmail_date != yesterday
            logger.debug("Skipping killmail #{killmail_id}. #{killmail_date} != #{yesterday}")
            return
          end

          return if options['region'] && options['region'].exclude?(killmail['region'][:itemname])

          csv << [
            killmail_id,
            killmail_hash,
            killmail_date,
            DateTime.parse(killmail['killmail_time']).strftime("%H:%M"),
            killmail['ship'][:typename],
            killmail['alliance']['name'],
            killmail['corporation']['name'],
            killmail['region'][:itemname],
            killmail['constellation'][:itemname],
            killmail['solar_system'][:itemname],
            killmail['attackers'].count,
            killmail['top_attacker_ship_type'][:typename],
            killmail['top_attacker_alliance']['name'],
            killmail['top_attacker_corporation']['name'],
            killmail['zkb']['fittedValue'],
            killmail['zkb']['droppedValue'],
            killmail['zkb']['destroyedValue'],
            killmail['zkb']['totalValue']
          ]
          @count += 1
        end

        def close
          csv.close
          logger.info("Wrote #{count} killmail(s) to #{output_file}")
        end

        private

        FIELDS = %w[id hash date time ship alliance corporation region constellation solar_system attacker_count top_attacker_ship top_attacker_alliance top_attacker_corporation fitted_value dropped_value destroyed_value total_value]

        attr_reader :headers_written, :output_file, :options, :logger, :count, :yesterday

        def csv
          @csv ||= CSV.open(output_file, 'w')
        end
      end
    end
  end
end
