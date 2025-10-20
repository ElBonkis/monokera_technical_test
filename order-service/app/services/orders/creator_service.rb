class Orders::CreatorService < ApplicationService
  attr_reader :order, :customer_data, :error_type, :error_message, :errors, :status_code

  def initialize(order_params)
    @order_params = order_params
    @order = nil
    @customer_data = nil
    @error_type = nil
    @error_message = nil
    @errors = []
    @status_code = nil
  end

  def call
    validate_params
    fetch_customer
    create_order
    publish_event if success?

    self
  end

  def success?
    @error_type.nil?
  end

  private

  def validate_params
    validator = Orders::ParamsValidator.new(@order_params)

    unless validator.valid?
      @error_type = 'validation_error'
      @error_message = 'Invalid order parameters'
      @errors = validator.errors
      @status_code = :bad_request
    end
  end

  def fetch_customer
    return if error_type.present?

    customer_fetcher = Customers::FetcherService.new(@order_params[:customer_id])
    result = customer_fetcher.call

    if result.success?
      @customer_data = result.customer_data
    else
      @error_type = result.error_type
      @error_message = result.error_message
      @status_code = result.status_code
    end
  end

  def create_order
    return if error_type.present?

    @order = Order.new(@order_params)

    unless @order.save
      @error_type = 'validation_error'
      @error_message = 'Failed to create order'
      @errors = @order.errors.full_messages
      @status_code = :unprocessable_entity
    end
  end

  def publish_event
    PublishOrderEventJob.perform_later(@order.id, @customer_data.symbolize_keys)
  rescue => e
    Rails.logger.error "Failed to enqueue publish job: #{e.message}"
  end
end
