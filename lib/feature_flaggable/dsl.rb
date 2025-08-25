# frozen_string_literal: true

module FeatureFlaggable
  # DSL for registering segments and predicates for feature flags.
  class DSL
    def initialize(registry)
      @registry = registry
    end

    def segment(name, &)
      @registry.register_segment(name, &)
    end

    def predicate(name, &)
      @registry.register_predicate(name, &)
    end
  end
end
