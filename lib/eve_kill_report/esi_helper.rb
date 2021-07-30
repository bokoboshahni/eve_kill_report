require 'httpx/adapters/faraday'
require 'faraday-http-cache'

module EVEKillReport
  module ESIHelper
    protected

    def esi
      @esi ||= Faraday.new(headers: { 'User-Agent' => user_agent }) do |config|
        config.use(:http_cache, store: EVEKillReport.cache, logger: logger) if options['cache']
        config.request :retry, max: 10
        config.adapter :httpx
      end
    end
  end
end
