require 'rails_helper'

RSpec.describe Customers::Fetcher do
  let(:customer_id) { 1 }
  let(:customer_data) { { 'id' => 1, 'name' => 'John Doe' } }

  describe '#call' do
    context 'when customer exists' do
      before do
        allow_any_instance_of(CustomerServiceClient)
          .to receive(:get_customer)
          .and_return(customer_data)
      end

      it 'returns success with customer data' do
        result = described_class.call(customer_id)

        expect(result.success?).to be true
        expect(result.customer_data).to eq(customer_data)
      end
    end

    context 'when customer not found' do
      before do
        allow_any_instance_of(CustomerServiceClient)
          .to receive(:get_customer)
          .and_return(nil)
      end

      it 'returns failure with not_found error' do
        result = described_class.call(customer_id)

        expect(result.success?).to be false
        expect(result.error_type).to eq('customer_not_found')
        expect(result.status_code).to eq(:not_found)
      end
    end

    context 'when service is unavailable' do
      before do
        allow_any_instance_of(CustomerServiceClient)
          .to receive(:get_customer)
          .and_raise(Faraday::ConnectionFailed)
      end

      it 'returns failure with service_unavailable error' do
        result = described_class.call(customer_id)

        expect(result.success?).to be false
        expect(result.error_type).to eq('service_unavailable')
      end
    end
  end
end
