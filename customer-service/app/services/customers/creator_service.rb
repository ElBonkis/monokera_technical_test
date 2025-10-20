class Customers::CreatorService < ApplicationService
  attr_reader :customer, :error_type, :error_message, :errors, :status_code

  def initialize(customer_params)
    @customer_params = customer_params
    @customer = nil
    @error_type = nil
    @error_message = nil
    @errors = []
    @status_code = nil
  end

  def call
    create_customer

    self
  end

  def success?
    @error_type.nil?
  end

  private

  def create_customer
    return if error_type.present?

    @customer = Customer.new(@customer_params)

    unless @customer.save
      @error_type = 'validation_error'
      @error_message = 'Failed to create customer'
      @errors = @customer.errors.full_messages
      @status_code = :unprocessable_entity
    end
  end
end
