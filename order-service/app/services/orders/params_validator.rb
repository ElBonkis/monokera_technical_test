class Orders::ParamsValidator < ApplicationService
  REQUIRED_FIELDS = [ :customer_id, :product_name, :quantity, :price ].freeze

  attr_reader :errors

  def initialize(params)
    @params = params
    @errors = []
  end

  def valid?
    validate_presence
    validate_types
    @errors.empty?
  end

  private

  def validate_presence
    missing_fields = REQUIRED_FIELDS.select { |field| @params[field].blank? }

    if missing_fields.any?
      @errors << "Missing required fields: #{missing_fields.join(', ')}"
    end
  end

  def validate_types
    return if @params[:customer_id].blank?

    unless @params[:customer_id].to_i > 0
      @errors << "customer_id must be a positive integer"
    end

    if @params[:quantity].present? && @params[:quantity].to_i <= 0
      @errors << "quantity must be greater than 0"
    end

    if @params[:price].present? && @params[:price].to_f <= 0
      @errors << "price must be greater than 0"
    end
  end
end