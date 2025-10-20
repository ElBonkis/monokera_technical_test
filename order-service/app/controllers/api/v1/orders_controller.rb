class Api::V1::OrdersController < ApplicationController
  def index
    result = Orders::MapperService.call(
      customer_id: params[:customer_id]
    )

    render json: result, status: :ok
  end

  def show
    order = Order.find(params[:id])
    serializer = OrderWithCustomerSerializer.new(order)
    render json: serializer.as_json, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Order not found' }, status: :not_found
  end

  def create
    result = Orders::CreatorService.call(order_params)

    if result.success?
      render json: {
        message: 'Order created successfully',
        order: result.order,
        customer: result.customer_data
      }, status: :created
    else
      render json: {
        error: result.error_type,
        message: result.error_message,
        details: result.errors
      }, status: result.status_code
    end
  end

  private

  def order_params
    params.require(:order).permit(:customer_id, :product_name, :quantity, :price, :status)
  end
end
