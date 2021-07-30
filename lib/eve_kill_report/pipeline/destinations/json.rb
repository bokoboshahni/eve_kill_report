require 'oj'

module EVEKillReport
  class Pipeline
    module Destinations
      class JSON
        def initialize(options = {})
          @output_file = options[:output]
          @options = options
          @logger = options['logger']
          @killmails = []
          @yesterday = (Time.now.utc - 1.day).to_date
        end

        def write(killmail)
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

          killmails << killmail
        end

        def close
          File.write(output_file, Oj.dump(killmails))
          logger.info("Wrote #{killmails.count} killmail(s) to #{output_file}")
        end

        private

        attr_reader :killmails, :output_file, :options, :logger, :yesterday
      end
    end
  end
end
