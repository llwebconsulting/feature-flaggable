# frozen_string_literal: true

require_relative "feature_flaggable/version"
require_relative "feature_flaggable/config"
require_relative "feature_flaggable/railtie" if defined?(Rails::Railtie)

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
