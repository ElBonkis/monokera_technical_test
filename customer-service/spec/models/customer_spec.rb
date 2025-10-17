require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validations' do
    subject { build(:customer) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:address) }
    
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }
    it { should validate_length_of(:address).is_at_least(5).is_at_most(255) }
    
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    
    it { should validate_numericality_of(:orders_count).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'callbacks' do
    it 'normalizes email before save' do
      customer = create(:customer, email: 'TEST@EXAMPLE.COM')
      expect(customer.email).to eq('test@example.com')
    end
  end

  describe 'scopes' do
    let!(:inactive_customer) { create(:customer, orders_count: 0) }
    let!(:active_customer) { create(:customer, :active) }

    it 'returns only active customers' do
      expect(Customer.active).to include(active_customer)
      expect(Customer.active).not_to include(inactive_customer)
    end
  end
end