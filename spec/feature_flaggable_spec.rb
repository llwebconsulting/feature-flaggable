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
