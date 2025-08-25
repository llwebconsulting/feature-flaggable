# frozen_string_literal: true

require 'yaml'
require_relative 'normalizer'

module FeatureFlaggable
  # Loader parses and normalizes the feature flag YAML config, supporting environment-aware
  # sections, normalization to canonical forms, percent clamping, and error handling.
  class Loader
    ALLOWED_KEYS = %w[scopes segments predicates percent].freeze
    SCALAR_ALL = 'all'
    SCALAR_NONE = 'none'

    def initialize(config: FeatureFlaggable.config, logger: nil, strict: false)
      @config = config
      @logger = logger || @config.logger
      @strict = strict
    end

    def load!
      normalizer = FeatureFlaggable::Normalizer.new(logger: @logger, strict: @strict)
      env_hash.each_with_object({}) do |(flag, value), out|
        out[flag.to_sym] = normalizer.normalize(flag, value)
      end
    rescue StandardError => e
      raise if @strict

      handle_error("Failed to load feature flags: #{e.message}")
      {}
    end

    private

    def raw_file
      @raw_file ||= YAML.load_file(@config.config_path)
    end

    def env_hash
      @env_hash ||= @config.env && raw_file[@config.env] ? raw_file[@config.env] : raw_file
    end

    def handle_error(msg)
      @strict ? raise(msg.to_s) : @logger.error(msg)
    end
  end
end
