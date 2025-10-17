require 'rails_helper'

RSpec.describe MessageBrokerFactory do
  describe '.create' do
    it 'creates RabbitMQ adapter by default' do
      adapter = described_class.create
      expect(adapter).to be_a(RabbitmqAdapter)
    end

    it 'creates RabbitMQ adapter explicitly' do
      adapter = described_class.create(:rabbitmq)
      expect(adapter).to be_a(RabbitmqAdapter)
    end

    it 'raises error for unknown adapter type' do
      expect {
        described_class.create(:unknown)
      }.to raise_error(ArgumentError, /Unknown broker type/)
    end

    it 'passes options to adapter' do
      adapter = described_class.create(:rabbitmq, exchange_name: 'test.exchange')
      expect(adapter.exchange.name).to eq('test.exchange')
    end
  end

  describe '.available_adapters' do
    it 'returns list of available adapters' do
      expect(described_class.available_adapters).to include(:rabbitmq)
    end
  end
end
