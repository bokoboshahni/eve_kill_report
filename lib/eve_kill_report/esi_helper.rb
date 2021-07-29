require 'httpx'
require 'json'

module EVEKillReport
  module ESIHelper
    protected

    def esi
      @esi ||= HTTPX.plugin(:retries).max_retries(10).with_headers('User-Agent' => user_agent)
    end
  end
end
