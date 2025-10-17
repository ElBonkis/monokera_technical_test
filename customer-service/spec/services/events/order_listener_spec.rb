require 'rails_helper'

RSpec.describe Events::OrderListener do
  let(:customer) { create(:customer, orders_count: 5) }
  let(:message) do
    {
      'event_type' => 'order.created',
      'data' => {
        'order' => {
          'id' => 123,
          'customer_id' => customer.id
        }
      }
    }
  end

  describe '#call' do
    it 'increments customer orders_count' do
      expect {
        described_class.call(message)
      }.to change { customer.reload.orders_count }.from(5).to(6)
    end

    it 'logs success' do
      expect(Rails.logger).to receive(:info).with(/Updated orders_count/)
      described_class.call(message)
    end

    it 'raises error when customer not found' do
      invalid_message = message.deep_dup
      invalid_message['data']['order']['customer_id'] = 99999

      expect {
        described_class.call(invalid_message)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'handles unknown event types' do
      unknown_message = message.merge('event_type' => 'unknown.event')

      expect(Rails.logger).to receive(:warn).with(/Unknown event type/)
      described_class.call(unknown_message)
    end
  end
end
