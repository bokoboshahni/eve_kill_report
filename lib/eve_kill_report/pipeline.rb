require 'concurrent/edge/lock_free_queue'
require 'concurrent/edge/throttle'
require 'etc'
require 'tty-progressbar'

require_relative './pipeline/sources/zkillboard'
require_relative './pipeline/transforms/esi_killmails'
require_relative './pipeline/transforms/killmail_alliances'
require_relative './pipeline/transforms/killmail_attackers'
require_relative './pipeline/transforms/killmail_corporations'
require_relative './pipeline/transforms/killmail_locations'
require_relative './pipeline/transforms/killmail_types'
require_relative './pipeline/destinations/comma_separated'
require_relative './pipeline/destinations/excel'
require_relative './pipeline/destinations/google_sheets'
require_relative './pipeline/destinations/json'

module EVEKillReport
  class Pipeline
    def initialize(options = {})
      @destinations = options[:destinations]
      @transforms = options.fetch(:transforms, DEFAULT_TRANSFORMS)
      @static_data = options[:static_data]
      @logger = options[:logger]
      @max_threads = options.fetch(:max_threads, DEFAULT_MAX_THREADS)
      @options = options
    end

    def run
      extract
      transform
      load
    end

    private

    attr_reader :destinations, :killmails, :logger, :options, :static_data, :transforms, :max_threads

    DEFAULT_MAX_THREADS = Etc.nprocessors

    DEFAULT_TRANSFORMS = [
      EVEKillReport::Pipeline::Transforms::ESIKillmails,
      EVEKillReport::Pipeline::Transforms::KillmailLocations,
      EVEKillReport::Pipeline::Transforms::KillmailAlliances,
      EVEKillReport::Pipeline::Transforms::KillmailCorporations,
      EVEKillReport::Pipeline::Transforms::KillmailTypes,
      EVEKillReport::Pipeline::Transforms::KillmailAttackers
    ]

    def extract
      @killmails = EVEKillReport::Pipeline::Sources::ZKillboard.new(options).extract
    end

    def transform
      transforms.each do |klass|
        logger.info("Running transform #{klass.name} against #{killmails.count} killmail(s)")
        if options['progress']
          progress = TTY::ProgressBar.new("Transforming killmail data with #{klass.name} [:bar]", total: killmails.count)
          progress.start
        end
        threads = killmails.map do |killmail|
          Thread.new do
            throttle.acquire do
              logger.debug("Running transform #{klass.name} for killmail #{killmail['killmail_id']}")
              klass.new(options).process(killmail)
              progress.advance if options['progress']
            end
          end
        end
        threads.each(&:join)
      end
    end

    def load
      threads = destinations.keys.map do |klass|
        Thread.new do
          logger.debug("Formatting output with #{klass.name}")
          destination_options = options.merge(output: destinations[klass])
          destination = klass.new(destination_options)
          killmails.each do |killmail|
            destination.write(killmail)
          end
          destination.close
        end
      end
      threads.each(&:join)
    end

    def throttle
      @throttle ||= Concurrent::Throttle.new(max_threads)
    end
  end
end
