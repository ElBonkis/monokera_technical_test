require 'rails_helper'

RSpec.describe Orders::Creator do
  let(:customer_data) { { 'id' => 1, 'name' => 'John Doe' } }
  let(:valid_params) do
    {
      customer_id: 1,
      product_name: 'Laptop',
      quantity: 2,
      price: 1500.00
    }
  end

  before do
    allow_any_instance_of(Customers::Fetcher)
      .to receive(:call)
      .and_return(double(success?: true, customer_data: customer_data))
  end

  describe '#call' do
    it 'creates an order successfully' do
      expect {
        described_class.call(valid_params)
      }.to change(Order, :count).by(1)
    end

    it 'returns success status' do
      result = described_class.call(valid_params)
      expect(result.success?).to be true
      expect(result.order).to be_a(Order)
      expect(result.customer_data).to eq(customer_data)
    end

    it 'enqueues publish job' do
      expect {
        described_class.call(valid_params)
      }.to have_enqueued_job(PublishOrderEventJob)
    end
  end

  describe 'validation errors' do
    it 'fails with missing customer_id' do
      invalid_params = valid_params.except(:customer_id)
      result = described_class.call(invalid_params)
      
      expect(result.success?).to be false
      expect(result.error_type).to eq('validation_error')
    end

    it 'fails with invalid price' do
      invalid_params = valid_params.merge(price: -10)
      result = described_class.call(invalid_params)
      
      expect(result.success?).to be false
    end
  end

  describe 'customer service errors' do
    before do
      allow_any_instance_of(Customers::Fetcher)
        .to receive(:call)
        .and_return(double(
          success?: false,
          error_type: 'customer_not_found',
          error_message: 'Customer not found',
          status_code: :not_found
        ))
    end

    it 'fails when customer not found' do
      result = described_class.call(valid_params)
      
      expect(result.success?).to be false
      expect(result.error_type).to eq('customer_not_found')
    end
  end
end