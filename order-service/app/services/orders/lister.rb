class Orders::Lister < ApplicationService
  attr_reader :customer_id

  def initialize(customer_id: nil)
    @customer_id = customer_id
  end

  def call
    orders = fetch_orders

    {
      orders: orders,
      total: orders.count,
      filtered_by: customer_id ? "customer_#{customer_id}" : "all"
    }
  end

  private

  def fetch_orders
    if customer_id.present?
      Order.by_customer(customer_id).recent
    else
      Order.recent
    end
  end
end
