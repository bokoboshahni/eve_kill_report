# frozen_string_literal: true

require 'active_support/cache'
require 'active_support/cache/redis_cache_store'
require 'active_support/notifications'
require 'redis/connection/hiredis'

require_relative "eve_kill_report/version"

module EVEKillReport
  class Error < StandardError; end

  def self.cache
    @cache ||= ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/8'))
  end
end
