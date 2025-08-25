# frozen_string_literal: true

require_relative 'feature_flaggable/version'
require_relative 'feature_flaggable/config'
require_relative 'feature_flaggable/railtie' if defined?(Rails::Railtie)
require_relative 'feature_flaggable/registry'
require_relative 'feature_flaggable/evaluator'
require_relative 'feature_flaggable/dsl'

# FeatureFlaggable provides a lightweight, Ruby-first feature flag DSL and YAML configuration
# for Rails and Ruby applications. See README for usage and configuration details.
module FeatureFlaggable
  class Error < StandardError; end

  class << self
    def config
      @config ||= Config.new
    end

    def registry
      @registry ||= Registry.new
    end

    def evaluator
      @evaluator ||= Evaluator.new(registry: registry, config: config)
    end

    def configure
      yield config if block_given?
    end

    def enabled?(flag, user:, context: {})
      evaluator.enabled?(flag, user: user, context: context)
    end

    def overridden?(flag)
      evaluator.overridden?(flag)
    end

    def override(flag, value)
      registry.override(flag, value)
    end

    def clear_override(flag)
      registry.clear_override(flag)
    end

    def define(&)
      dsl = DSL.new(registry)
      dsl.instance_eval(&) if block_given?
    end

    def flaggable(flag, user:, context: {})
      yield if enabled?(flag, user: user, context: context)
    end
  end
end
