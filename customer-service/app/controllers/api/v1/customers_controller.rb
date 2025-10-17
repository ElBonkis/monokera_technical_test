class Api::V1::CustomersController < ApplicationController
  def index
    result = Customers::Lister.call
    render json: result, status: :ok
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
end
