require 'httpx/adapters/faraday'
require 'faraday-http-cache'
require 'json'
require 'retriable'

module EVEKillReport
  class Pipeline
    module Sources
      class ZKillboard
        include Enumerable

        def initialize(options = {})
          @user_agent = options[:user_agent]
          @past_seconds = options[:past_seconds]
          @year = options[:year]
          @month = options[:month]
          @alliance_ids = options[:alliance_ids]
          @logger = options[:logger]
          @options = options
        end

        def extract
          fetch_all
          self
        end

        def each
          killmails.each { |k| yield k }
        end

        private

        attr_reader :killmails, :alliance_ids, :past_seconds, :year, :month, :user_agent, :options, :logger

        def fetch_all
          @killmails = alliance_ids.each_with_object([]) do |alliance_id, all_killmails|
            if options['progress']
              progress = TTY::ProgressBar.new('Downloading killmails from zKillboard [:bar]', total: nil)
              progress.start
            end

            Retriable.retriable on: [Oj::ParseError], tries: 10 do
              alliance_killmails = []
              page_count = 1
              loop do
                url = "https://zkillboard.com/api/allianceID/#{alliance_id}/losses/#{date_path}/page/#{page_count}/"
                response = zkillboard.get(url)
                data = Oj.load(response.body)

                logger.debug("Got #{data.count} killmail(s) from #{url}")

                break if data.empty?

                alliance_killmails.push(*data)
                page_count += 1
                sleep(15)
              end

              all_killmails.push(*alliance_killmails)
              logger.info("Indexed #{alliance_killmails.count} total killmail(s) for alliance #{alliance_id}")
            end

            progress.finish if options['progress']
          end

          logger.debug("Indexed #{@killmails.count} total killmail(s) from zKillboard")
        end

        def date_path
          if past_seconds
            "pastSeconds/#{past_seconds}"
          elsif month && year
            "year/#{year}/month/#{month}"
          end
        end

        def zkillboard
          @zkillboard ||= Faraday.new(headers: { 'User-Agent' => user_agent }) do |config|
            config.use(:http_cache, store: EVEKillReport.cache, logger: logger) if options['cache']
            config.request :retry, max: 10
            config.adapter :httpx
          end
        end
      end
    end
  end
end
