# frozen_string_literal: true

begin
  require 'rails/railtie'
rescue LoadError
  # Not in a Rails environment; skip Railtie
end

module FeatureFlaggable
  class Railtie < ::Rails::Railtie
    initializer "feature_flaggable.configure" do
      # Ensures FeatureFlaggable is configured early in Rails boot
      FeatureFlaggable.config
    end

    initializer "feature_flaggable.helpers" do
      ActiveSupport.on_load(:action_controller) do
        # Placeholder: include controller helpers if needed
      end
      ActiveSupport.on_load(:action_view) do
        # Placeholder: include view helpers if needed
      end
    end
  end
end
