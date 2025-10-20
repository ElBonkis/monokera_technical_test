class Customers::FetcherService < ApplicationService
  attr_reader :customer_data, :error_type, :error_message, :status_code

  def initialize(customer_id)
    @customer_id = customer_id
    @customer_data = nil
    @error_type = nil
    @error_message = nil
    @status_code = nil
  end

  def call
    fetch_from_customer_service
    self
  end

  def success?
    @error_type.nil?
  end

  private

  def fetch_from_customer_service
    client = CustomerServiceClient.new
    @customer_data = client.get_customer(@customer_id)

    if @customer_data.nil?
      @error_type = 'customer_not_found'
      @error_message = "Customer with ID #{@customer_id} not found"
      @status_code = :not_found
    end
  rescue Faraday::ConnectionFailed => e
    @error_type = 'service_unavailable'
    @error_message = 'Customer Service is currently unavailable'
    @status_code = :service_unavailable
    Rails.logger.error "Customer Service connection failed: #{e.message}"
  rescue CustomerServiceError => e
    @error_type = 'customer_service_error'
    @error_message = e.message
    @status_code = :bad_gateway
    Rails.logger.error "Customer Service error: #{e.message}"
  end
end
