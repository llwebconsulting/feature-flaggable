# frozen_string_literal: true

module FeatureFlaggable
  class Evaluator
    def initialize(registry:, config:, cache: nil)
      @registry = registry
      @config = config
      @cache = cache
    end

    def enabled?(_flag, user:, context: {})
      # Stub: always false
      false
    end

    def overridden?(_flag)
      # Stub: always false
      false
    end
    # Add evaluation logic here as needed
  end
end
