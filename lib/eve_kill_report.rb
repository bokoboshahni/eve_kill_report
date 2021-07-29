# frozen_string_literal: true

require 'active_support/cache'
require 'active_support/cache/file_store'
require 'active_support/notifications'

require_relative "eve_kill_report/version"

module EVEKillReport
  class Error < StandardError; end

  def self.cache
    @cache ||= begin
      cache_path = "#{Dir.home}/.config/eve-kill-report/cache"
      FileUtils.mkdir_p(cache_path)
      ActiveSupport::Cache::FileStore.new("#{Dir.home}/.config/eve-kill-report/cache")
    end
  end
end
