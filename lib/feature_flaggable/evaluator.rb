# frozen_string_literal: true

module FeatureFlaggable
  # Evaluator determines if a feature flag is enabled for a given user and context.
  class Evaluator
    def initialize(registry:, config:, cache: nil)
      @registry = registry
      @config = config
      @cache = cache
    end
  end
end
