# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'feature_flaggable/loader'

RSpec.describe FeatureFlaggable::Loader do
  let(:logger) { Logger.new(nil) }
  let(:config) { FeatureFlaggable::Config.new }
  let(:loader) { described_class.new(config: config, logger: logger) }

  def with_temp_yaml(yaml)
    file = Tempfile.new('feature_flags.yml')
    file.write(yaml)
    file.close
    config.config_path = file.path
    yield
  ensure
    file.unlink
  end

  context 'with flat YAML' do
    it 'parses scalar all/none' do
      yaml = "
      new_checkout: all
      billing_dashboard: none
      "
      with_temp_yaml(yaml) do
        result = loader.load!
        expect(result[:new_checkout]).to eq(:all)
        expect(result[:billing_dashboard]).to eq(:none)
      end
    end

    it 'parses array as scopes' do
      yaml = "
      new_checkout: [admin, business]
      "
      with_temp_yaml(yaml) do
        result = loader.load!
        expect(result[:new_checkout]).to eq(scopes: %i[admin business])
      end
    end

    it 'parses object form' do
      yaml = "
      rtp_payouts:
        scopes: [business]
        segments: [early_adopters]
        percent: 25
        predicates: [approved_business]
      "
      with_temp_yaml(yaml) do
        result = loader.load!
        expect(result[:rtp_payouts]).to eq(
          scopes: [:business],
          segments: [:early_adopters],
          percent: 25,
          predicates: [:approved_business]
        )
      end
    end
  end

  context 'with env-keyed YAML' do
    it 'parses current env section' do
      yaml = "
      test:
        new_checkout: all
        billing_dashboard: none
      "
      config.env = 'test'
      with_temp_yaml(yaml) do
        result = loader.load!
        expect(result[:new_checkout]).to eq(:all)
        expect(result[:billing_dashboard]).to eq(:none)
      end
    end
  end

  it 'warns and clamps percent out of bounds' do
    yaml = "
    flag:
      percent: 150
    "
    expect(logger).to receive(:warn).with(/clamped/)
    with_temp_yaml(yaml) do
      result = loader.load!
      expect(result[:flag][:percent]).to eq(100)
    end
  end

  it 'warns on unknown keys' do
    yaml = "
    flag:
      scopes: [admin]
      foo: bar
    "
    expect(logger).to receive(:warn).with(/Unknown key/)
    with_temp_yaml(yaml) { loader.load! }
  end

  it 'raises on unknown key in strict mode' do
    yaml = "
    flag:
      scopes: [admin]
      foo: bar
    "
    strict_loader = described_class.new(config: config, logger: logger, strict: true)
    with_temp_yaml(yaml) do
      expect { strict_loader.load! }.to raise_error(ArgumentError, /Unknown key/)
    end
  end
end
