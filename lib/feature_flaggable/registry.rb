# frozen_string_literal: true

# Registry stores feature flag overrides, segments, and predicates.
module FeatureFlaggable
  class Registry
    def initialize
      @overrides = {}
      @segments = {}
      @predicates = {}
    end

    def override(flag, value)
      @overrides[flag.to_sym] = value
    end

    def clear_override(flag)
      @overrides.delete(flag.to_sym)
    end

    def overridden?(flag)
      @overrides.key?(flag.to_sym)
    end

    def register_segment(name, &block)
      @segments[name.to_sym] = block
    end

    def register_predicate(name, &block)
      @predicates[name.to_sym] = block
    end
  end
end
