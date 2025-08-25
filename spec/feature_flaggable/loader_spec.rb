# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'feature_flaggable/loader'

RSpec.describe FeatureFlaggable::Loader do
  let(:logger) { Logger.new(nil) }
  let(:config) { FeatureFlaggable::Config.new }

  def with_temp_yaml(yaml)
    file = Tempfile.new('feature_flags.yml')
    file.write(yaml)
    file.close
    config.config_path = file.path
    yield
  ensure
    file.unlink
  end

  it 'loads flat YAML and delegates to normalizer' do
    yaml = "
    new_checkout: all
    billing_dashboard: none
    "
    with_temp_yaml(yaml) do
      normalizer = instance_double(FeatureFlaggable::Normalizer)
      expect(FeatureFlaggable::Normalizer).to receive(:new).and_return(normalizer)
      expect(normalizer).to receive(:normalize).with('new_checkout', 'all').and_return(:all)
      expect(normalizer).to receive(:normalize).with('billing_dashboard', 'none').and_return(:none)
      loader = described_class.new(config: config, logger: logger)
      result = loader.load!
      expect(result).to eq(new_checkout: :all, billing_dashboard: :none)
    end
  end

  it 'loads env-keyed YAML and delegates to normalizer' do
    yaml = "
    test:
      new_checkout: all
      billing_dashboard: none
    "
    config.env = 'test'
    with_temp_yaml(yaml) do
      normalizer = instance_double(FeatureFlaggable::Normalizer)
      expect(FeatureFlaggable::Normalizer).to receive(:new).and_return(normalizer)
      expect(normalizer).to receive(:normalize).with('new_checkout', 'all').and_return(:all)
      expect(normalizer).to receive(:normalize).with('billing_dashboard', 'none').and_return(:none)
      loader = described_class.new(config: config, logger: logger)
      result = loader.load!
      expect(result).to eq(new_checkout: :all, billing_dashboard: :none)
    end
  end

  it 'raises in strict mode on YAML error' do
    config.env = 'test'
    allow(YAML).to receive(:load_file).and_raise(Psych::SyntaxError.new('file', 1, 1, 1, 'bad', 'bad'))
    loader = described_class.new(config: config, logger: logger, strict: true)
    expect { loader.load! }.to raise_error(Psych::SyntaxError)
  end

  it 'logs error and returns empty hash on YAML error in non-strict mode' do
    config.env = 'test'
    allow(YAML).to receive(:load_file).and_raise(Psych::SyntaxError.new('file', 1, 1, 1, 'bad', 'bad'))
    loader = described_class.new(config: config, logger: logger, strict: false)
    expect(logger).to receive(:error).with(/Failed to load feature flags/)
    expect(loader.load!).to eq({})
  end
end
