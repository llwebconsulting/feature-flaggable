# frozen_string_literal: true

require 'logger'

module FeatureFlaggable
  # This class holds configuration for FeatureFlaggable, including YAML path, environment,
  # reload/caching options, logger, and user scope resolution.
  class Config
    attr_accessor :config_path, :env, :reload_on_change, :cache_backend, :logger, :scope_resolver

    def initialize
      @config_path = 'config/feature_flags.yml'
      @env = nil
      @reload_on_change = false
      @cache_backend = :none
      @logger = defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : Logger.new($stdout)
      @scope_resolver = default_scope_resolver
    end

    private

    def default_scope_resolver
      lambda do |user|
        if user.respond_to?(:user_type)
          user.user_type&.to_sym
        elsif user.respond_to?(:role)
          user.role&.to_sym
        end
      end
    end
  end
end
