class OrderWithCustomerSerializer
  def initialize(order, customer_data = nil)
    @order = order
    @customer_data = customer_data
  end

  def as_json
    {
      id: @order.id,
      product_name: @order.product_name,
      quantity: @order.quantity,
      price: @order.price,
      status: @order.status,
      created_at: @order.created_at,
      updated_at: @order.updated_at,
      customer: @customer_data || fetch_customer_data
    }
  end

  private

  def fetch_customer_data
    result = Customers::FetcherService.new(@order.customer_id).call
    result.success? ? result.customer_data : { error: 'Customer data unavailable' }
  rescue => e
    Rails.logger.error "Error fetching customer: #{e.message}"
    { error: 'Customer data unavailable' }
  end
end
