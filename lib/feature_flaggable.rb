# frozen_string_literal: true

require_relative 'feature_flaggable/version'
require_relative 'feature_flaggable/config'
require_relative 'feature_flaggable/railtie' if defined?(Rails::Railtie)

# FeatureFlaggable provides a lightweight, Ruby-first feature flag DSL and YAML configuration
# for Rails and Ruby applications. See README for usage and configuration details.
module FeatureFlaggable
  class Error < StandardError; end

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config if block_given?
    end
  end
end
