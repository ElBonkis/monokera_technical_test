class Events::OrderPublisher < ApplicationService
  def initialize(order, customer_data)
      @order = order
      @customer_data = customer_data
      @broker = MessageBroker
    end

    def call
      validate_broker!
      event_data = build_event_payload
      @broker.publish('order.created', event_data)
      log_success
      true
    rescue => e
      log_error(e)
      raise
    end

    private

    def validate_broker!
      unless @broker
        raise StandardError, "MessageBroker not initialized"
      end
    end

    def build_event_payload
      {
        event_type: 'order.created',
        timestamp: Time.current.iso8601,
        version: '1.0',
        data: {
          order: {
            id: @order.id,
            customer_id: @order.customer_id,
            product_name: @order.product_name,
            quantity: @order.quantity,
            price: @order.price.to_s,
            total: (@order.quantity * @order.price).to_s,
            status: @order.status,
            created_at: @order.created_at.iso8601
          },
          customer: {
            id: @customer_data[:id] || @customer_data['id'],
            name: @customer_data[:name] || @customer_data['name'],
            address: @customer_data[:address] || @customer_data['address']
          }
        },
        metadata: {
          service: 'order-service',
          environment: Rails.env
        }
      }
    end

    def log_success
      Rails.logger.info "Order event published successfully for Order ##{@order.id}"
    end

    def log_error(error)
      Rails.logger.error "Failed to publish order event: #{error.message}"
      Rails.logger.error error.backtrace.first(5).join("\n")
    end
end
