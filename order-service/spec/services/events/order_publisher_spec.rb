require 'rails_helper'

RSpec.describe Events::OrderPublisher do
  let(:order) { create(:order) }
  let(:customer_data) { { id: 1, name: 'John Doe', address: '123 Street' } }

  describe '#call' do
    it 'publishes event to RabbitMQ' do
      expect(MessageBroker).to receive(:publish).with(
        'order.created',
        hash_including(event_type: 'order.created')
      )

      described_class.call(order, customer_data)
    end

    it 'includes order data in payload' do
      published_data = nil

      allow(MessageBroker).to receive(:publish) do |routing_key, data|
        published_data = data
      end

      described_class.call(order, customer_data)

      expect(published_data[:data][:order][:id]).to eq(order.id)
      expect(published_data[:data][:order][:product_name]).to eq(order.product_name)
    end

    it 'includes customer data in payload' do
      published_data = nil

      allow(MessageBroker).to receive(:publish) do |routing_key, data|
        published_data = data
      end

      described_class.call(order, customer_data)

      expect(published_data[:data][:customer][:name]).to eq('John Doe')
    end

    it 'logs success' do
      allow(MessageBroker).to receive(:publish)

      expect(Rails.logger).to receive(:info).with(/Order event published successfully/)

      described_class.call(order, customer_data)
    end

    it 'logs and raises error on failure' do
      allow(MessageBroker).to receive(:publish).and_raise(StandardError.new('Connection failed'))

      expect(Rails.logger).to receive(:error).at_least(:once)
      expect { described_class.call(order, customer_data) }.to raise_error(StandardError)
    end
  end
end
