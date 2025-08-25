# frozen_string_literal: true

require 'spec_helper'
require 'feature_flaggable/normalizer'

RSpec.describe FeatureFlaggable::Normalizer do
  let(:logger) { Logger.new(nil) }

  subject(:normalizer) { described_class.new(logger: logger, strict: false) }

  describe '#normalize' do
    it 'returns :all for scalar all' do
      expect(normalizer.normalize('flag', 'all')).to eq(:all)
      expect(normalizer.normalize('flag', :all)).to eq(:all)
    end

    it 'returns :none for scalar none' do
      expect(normalizer.normalize('flag', 'none')).to eq(:none)
      expect(normalizer.normalize('flag', :none)).to eq(:none)
    end

    it 'returns scopes for array' do
      expect(normalizer.normalize('flag', %w[admin business])).to eq(scopes: %i[admin business])
    end

    it 'normalizes object with all keys' do
      result = normalizer.normalize('flag', {
                                      'scopes' => ['admin'],
                                      'segments' => ['early_adopters'],
                                      'percent' => 25,
                                      'predicates' => ['approved_business']
                                    })
      expect(result).to eq(
        scopes: [:admin],
        segments: [:early_adopters],
        percent: 25,
        predicates: [:approved_business]
      )
    end

    it 'normalizes scopes: all/none in object' do
      expect(normalizer.normalize('flag', { 'scopes' => 'all' })).to eq(scopes: :all)
      expect(normalizer.normalize('flag', { 'scopes' => 'none' })).to eq(scopes: :none)
    end

    it 'clamps percent and warns if out of bounds' do
      expect(logger).to receive(:warn).with(/clamped/)
      result = normalizer.normalize('flag', { 'percent' => 150 })
      expect(result[:percent]).to eq(100)
    end

    it 'warns on unknown keys' do
      expect(logger).to receive(:warn).with(/Unknown key/)
      normalizer.normalize('flag', { 'foo' => 'bar' })
    end

    it 'returns :none and logs error for invalid value' do
      expect(logger).to receive(:error).with(/Invalid value/)
      expect(normalizer.normalize('flag', 123)).to eq(:none)
    end
  end

  context 'strict mode' do
    subject(:strict_normalizer) { described_class.new(logger: logger, strict: true) }

    it 'raises on unknown key' do
      expect { strict_normalizer.normalize('flag', { 'foo' => 'bar' }) }.to raise_error(ArgumentError, /Unknown key/)
    end

    it 'raises on invalid value' do
      expect { strict_normalizer.normalize('flag', 123) }.to raise_error(RuntimeError, /Invalid value/)
    end
  end
end
