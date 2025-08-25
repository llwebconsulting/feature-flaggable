# frozen_string_literal: true

RSpec.describe FeatureFlaggable do
  it 'has a version number' do
    expect(FeatureFlaggable::VERSION).not_to be nil
  end

  describe '.config and .configure' do
    it 'returns a config object' do
      expect(FeatureFlaggable.config).to be_a(FeatureFlaggable::Config)
    end

    it 'allows configuration via .configure' do
      FeatureFlaggable.configure do |c|
        c.config_path = 'custom/path.yml'
        c.env = 'test'
      end
      expect(FeatureFlaggable.config.config_path).to eq('custom/path.yml')
      expect(FeatureFlaggable.config.env).to eq('test')
    end
  end
end

RSpec.describe 'FeatureFlaggable Railtie integration' do
  it 'loads Railtie if Rails is present' do
    stub_const('Rails', Class.new)
    railtie_class = Class.new do
      def self.initializer(*); end
    end
    stub_const('Rails::Railtie', railtie_class)
    expect { load File.expand_path('../lib/feature_flaggable.rb', __dir__) }.not_to raise_error
  end
end

RSpec.describe FeatureFlaggable, 'public API' do
  let(:user) { double('User', user_type: :admin) }
  let(:context) { { business: double('Business') } }

  it 'can define segments and predicates' do
    expect do
      FeatureFlaggable.define do
        segment :testers do |_user:, _context: {}|
          true
        end
        predicate :always_true do |_user:, _context: {}|
          true
        end
      end
    end.not_to raise_error
  end

  it 'executes block in flaggable if enabled? returns true' do
    allow(FeatureFlaggable).to receive(:enabled?).and_return(true)
    result = nil
    FeatureFlaggable.flaggable(:some_flag, user: user, context: context) { result = 42 }
    expect(result).to eq(42)
  end

  it 'does not execute block in flaggable if enabled? returns false' do
    allow(FeatureFlaggable).to receive(:enabled?).and_return(false)
    result = nil
    FeatureFlaggable.flaggable(:some_flag, user: user, context: context) { result = 42 }
    expect(result).to be_nil
  end
end
