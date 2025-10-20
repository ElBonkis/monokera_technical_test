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
      filtered_by: customer_id ? fetch_customer_data(customer_id) : "all"
    }
  end

  private

  def fetch_customer_data(customer_id)
    result = Customers::Fetcher.new(customer_id).call
    result.success? ? result.customer_data : { error: 'Customer data unavailable' }
  rescue => e
    Rails.logger.error "Error fetching customer: #{e.message}"
    { error: 'Customer data unavailable' }
  end

  def fetch_orders
    if customer_id.present?
      Order.by_customer(customer_id).recent
    else
      Order.recent
    end
  end
end
