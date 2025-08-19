# frozen_string_literal: true

require 'yaml'

module FeatureFlaggable
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
      raw = YAML.load_file(@config.config_path)
      env_hash = @config.env && raw[@config.env] ? raw[@config.env] : raw
      normalize_flags(env_hash)
    rescue StandardError => e
      raise if @strict

      handle_error("Failed to load feature flags: #{e.message}")
      {}
    end

    private

    def normalize_flags(hash)
      hash.each_with_object({}) do |(flag, value), out|
        out[flag.to_sym] = normalize_value(flag, value)
      end
    end

    def normalize_value(flag, value)
      case value
      when SCALAR_ALL, :all
        :all
      when SCALAR_NONE, :none
        :none
      when Array
        { scopes: value.map(&:to_sym) }
      when Hash
        norm = {}
        value.each do |k, v|
          if ALLOWED_KEYS.include?(k.to_s)
            norm[k.to_sym] =
              if k.to_s == 'scopes'
                normalize_scopes(v)
              elsif k.to_s == 'segments'
                Array(v).map(&:to_sym)
              elsif k.to_s == 'predicates'
                Array(v).map(&:to_sym)
              else
                k.to_s == 'percent' ? clamp_percent(flag, v) : v
              end
          else
            warn_unknown_key(flag, k)
          end
        end
        norm
      else
        handle_error("Invalid value for flag '#{flag}': #{value.inspect}")
        :none
      end
    end

    def normalize_scopes(val)
      return :all if val.to_s == SCALAR_ALL
      return :none if val.to_s == SCALAR_NONE

      Array(val).map(&:to_sym)
    end

    def clamp_percent(flag, val)
      n = val.to_i
      if n < 0 || n > 100
        @logger.warn("[FeatureFlaggable] Percent for '#{flag}' out of bounds (#{n}), clamped to 0..100")
        n = [[n, 0].max, 100].min
      end
      n
    end

    def warn_unknown_key(flag, key)
      msg = "[FeatureFlaggable] Unknown key '#{key}' in flag '#{flag}'"
      @strict ? raise(ArgumentError, msg) : @logger.warn(msg)
    end

    def handle_error(msg)
      @strict ? raise(msg.to_s) : @logger.error(msg)
    end
  end
end
