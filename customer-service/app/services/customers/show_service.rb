class Customers::ShowService < ApplicationService
  attr_reader :customer_data, :error_type, :error_message, :status_code

  def initialize(customer_id)
    @customer_id = customer_id
    @customer_data = nil
    @error_type = nil
    @error_message = nil
    @status_code = nil
  end

  def call
    fetch_customer
    self
  end

  def success?
    @error_type.nil?
  end

  private

  def fetch_customer
    customer = Customer.find(@customer_id)
    @customer_data = CustomerSerializer.new(customer).as_json
  rescue ActiveRecord::RecordNotFound
    @error_type = 'not_found'
    @error_message = "Customer with ID #{@customer_id} not found"
    @status_code = :not_found
  end
end
