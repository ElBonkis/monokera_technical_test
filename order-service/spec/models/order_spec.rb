require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:customer_id) }
    it { should validate_presence_of(:product_name) }
    it { should validate_presence_of(:quantity) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:status) }

    it { should validate_numericality_of(:customer_id).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:price).is_greater_than(0) }

    it { should validate_length_of(:product_name).is_at_least(2).is_at_most(255) }

    it 'validates status inclusion' do
      order = build(:order, status: 'pending')
      expect(order).to be_valid

      expect {
        order.status = 'invalid_status'
      }.to raise_error(ArgumentError, /'invalid_status' is not a valid status/)
    end
  end

  describe 'scopes' do
    let!(:old_order) { create(:order, created_at: 2.days.ago) }
    let!(:new_order) { create(:order, created_at: 1.day.ago) }

    it 'returns orders in descending order by creation date' do
      expect(Order.recent.first).to eq(new_order)
    end

    it 'filters orders by customer_id' do
      customer_order = create(:order, customer_id: 5)
      expect(Order.by_customer(5)).to include(customer_order)
    end
  end

  describe '#total' do
    it 'calculates the correct total' do
      order = build(:order, quantity: 3, price: 100.50)
      expect(order.total).to eq(301.50)
    end
  end

  describe 'status enum' do
    it 'allows valid statuses' do
      order = create(:order, status: 'pending')
      expect(order.status).to eq('pending')

      order.update!(status: 'completed')
      expect(order.status).to eq('completed')
    end

    it 'has enum methods' do
      order = create(:order, status: 'pending')
      expect(order.pending?).to be true
      expect(order.completed?).to be false
    end
  end
end
