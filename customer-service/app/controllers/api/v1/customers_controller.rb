class Api::V1::CustomersController < ApplicationController
  def index
    result = Customers::Lister.call
    render json: result, status: :ok
  end

  def create
    result = Customers::Creator.call(customer_params)

    if result.success?
      render json: CustomerSerializer.new(result.customer).as_json, status: :created
    else
      render json: {
        error: result.error_type,
        message: result.error_message,
        details: result.errors
      }, status: result.status_code
    end
  end

  def show
    result = Customers::ShowService.call(params[:id])

    if result.success?
      render json: result.customer_data, status: :ok
    else
      render json: {
        error: result.error_type,
        message: result.error_message
      }, status: result.status_code
    end
  end

  def customer_params
    params.require(:customer).permit(:name, :email, :address, :phone)
  end
end
