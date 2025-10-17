class Events::OrderListener < ApplicationService
  def initialize(message)
    @message = message
  end

  def call
    process_message
    true
  rescue => e
    Rails.logger.error "❌ Failed to process order event: #{e.message}"
    raise
  end

  private

  def process_message
    event_type = @message['event_type']

    case event_type
    when 'order.created'
      handle_order_created(@message['data'])
    else
      Rails.logger.warn "Unknown event type: #{event_type}"
    end
  end

  def handle_order_created(data)
    customer_id = extract_customer_id(data)
    order_id = extract_order_id(data)

    increment_customer_orders_count(customer_id, order_id)
  end

  def extract_customer_id(data)
    data.dig('order', 'customer_id') || data.dig(:order, :customer_id)
  end

  def extract_order_id(data)
    data.dig('order', 'id') || data.dig(:order, :id)
  end

  def increment_customer_orders_count(customer_id, order_id)
    customer = Customer.find_by(id: customer_id)

    if customer
      customer.increment!(:orders_count)
      Rails.logger.info "Updated orders_count for Customer ##{customer_id} (Order ##{order_id})"
    else
      Rails.logger.error "Customer ##{customer_id} not found"
      raise ActiveRecord::RecordNotFound, "Customer #{customer_id} not found"
    end
  end
end