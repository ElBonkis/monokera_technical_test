class PublishOrderEventJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound do |job, error|
    Rails.logger.warn "Order #{job.arguments.first} not found, discarding job"
  end

  def perform(order_id, customer_data)
    Rails.logger.info "Publishing event for Order ##{order_id}"

    order = Order.find(order_id)

    Events::OrderPublisher.call(order, customer_data)

    Rails.logger.info "Event published successfully for Order ##{order_id}"
  rescue => e
    Rails.logger.error "Failed to publish event for Order ##{order_id}: #{e.message}"
    raise
  end
end
