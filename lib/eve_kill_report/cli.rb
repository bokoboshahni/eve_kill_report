require 'active_support/core_ext/integer/time'
require 'json'
require 'thor'
require 'tty-logger'

require_relative '../eve_kill_report'
require_relative './esi_helper'
require_relative './pipeline'
require_relative './static_data'

module EVEKillReport
  class CLI < Thor
    include ESIHelper

    class_option :verbose
    class_option :debug

    desc 'victims [OPTIONS]', 'Generate a victim report'
    method_option :alliance, type: :string, repeatable: true
    method_option :alliance_ids, type: :array
    method_option :days, type: :numeric
    method_option :format, type: :string, repeatable: true
    method_option :output, type: :string, repeatable: true
    method_option :month, type: :numeric
    method_option :progress, type: :boolean
    method_option :region, type: :string, repeatable: true
    method_option :user_agent, type: :string
    method_option :year, type: :numeric
    method_option :yesterday, type: :boolean
    def victims
      @user_agent = options[:user_agent]

      opts = options.dup

      destination_keys = opts[:format].map { |v| FORMAT_DESTINATION_MAP[v] }
      opts[:destinations] = Hash[destination_keys.zip(options[:output])]

      if options['yesterday']
        opts.merge!(past_seconds: 2.days.seconds)
      elsif options['days']
        opts.merge!(past_seconds: options['days'].days.seconds) if options['days']
      end

      if opts[:alliance]
        opts[:alliance_ids] ||= []
        opts[:alliance].each do |alliance_name|
          Retriable.retriable on: [JSON::ParserError] do
            logger.debug("Searching for alliance: #{alliance_name}")
            response = esi.get("https://esi.evetech.net/latest/search", { 'categories' => 'alliance', 'search' => alliance_name, 'strict' => true })
            result = JSON.parse(response.body)

            if result.empty?
              logger.error "Alliance not found: #{alliance_name}"
              next
            end

            opts[:alliance_ids] << result['alliance'].first
          end
        end
      end

      opts[:alliance_ids].uniq!

      @config_dir = File.join(Dir.home, '.config', 'eve-kill-report')
      FileUtils.mkdir_p(config_dir)
      @static_data = EVEKillReport::StaticData.new(dir: config_dir, logger: logger)
      @static_data.download
      @static_data.parse

      opts.merge!(static_data: static_data, logger: logger)

      static_data.download

      EVEKillReport::Pipeline.new(opts).run
    end

    private

    FORMAT_DESTINATION_MAP = {
      'csv' => EVEKillReport::Pipeline::Destinations::CommaSeparated,
      'gsheet' => EVEKillReport::Pipeline::Destinations::GoogleSheets,
      'json' => EVEKillReport::Pipeline::Destinations::JSON,
      'xlsx' => EVEKillReport::Pipeline::Destinations::Excel
    }

    attr_reader :config_dir, :static_data, :user_agent

    def exit_on_failure?
      true
    end

    def logger
      @logger ||= TTY::Logger.new do |config|
        if options[:verbose]
          config.level = :info
        elsif options[:debug]
          config.level = :debug
        else
          config.level = :warn
        end
      end
    end
  end
end
