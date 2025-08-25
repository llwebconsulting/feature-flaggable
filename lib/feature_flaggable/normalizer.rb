# frozen_string_literal: true

module FeatureFlaggable
  # Normalizer handles the normalization of feature flag values,
  # converting them to canonical forms
  class Normalizer
    ALLOWED_KEYS = %w[scopes segments predicates percent].freeze
    SCALAR_ALL = 'all'
    SCALAR_NONE = 'none'

    def initialize(logger:, strict: false)
      @logger = logger
      @strict = strict
      @dispatch = {
        'scopes' => method(:normalize_scopes),
        'segments' => method(:normalize_segments),
        'predicates' => method(:normalize_predicates),
        'percent' => method(:normalize_percent)
      }
    end

    def normalize(flag, value)
      case value
      when SCALAR_ALL, :all then :all
      when SCALAR_NONE, :none then :none
      when Array then { scopes: value.map(&:to_sym) }
      when Hash then normalize_object(flag, value)
      else
        handle_error("Invalid value for flag '#{flag}': #{value.inspect}")
        :none
      end
    end

    private

    def normalize_object(flag, hash)
      norm = {}
      hash.each do |k, v|
        if @dispatch.key?(k.to_s)
          norm[k.to_sym] = @dispatch[k.to_s].call(v, flag)
        else
          warn_unknown_key(flag, k)
        end
      end
      norm
    end

    def normalize_scopes(val, _flag = nil)
      return :all if val.to_s == SCALAR_ALL
      return :none if val.to_s == SCALAR_NONE

      Array(val).map(&:to_sym)
    end

    def normalize_segments(val, _flag = nil)
      Array(val).map(&:to_sym)
    end

    def normalize_predicates(val, _flag = nil)
      Array(val).map(&:to_sym)
    end

    def normalize_percent(val, flag)
      n = val.to_i
      if n.negative? || n > 100
        @logger.warn("[FeatureFlaggable] Percent for '#{flag}' out of bounds (#{n}), clamped to 0..100")
        n = n.clamp(0, 100)
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
