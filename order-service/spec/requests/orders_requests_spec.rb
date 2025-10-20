require 'rails_helper'

RSpec.describe "Api::V1::Orders", type: :request do
  describe "GET /api/v1/orders" do
    let!(:orders) { create_list(:order, 3) }

    before { get "/api/v1/orders" }

    it "returns success status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all orders" do
      json_response = JSON.parse(response.body)
      expect(json_response["orders"].size).to eq(3)
    end

    context "when filtered by customer_id" do
      let(:customer_id) { 10 }
      let!(:customer_orders) { create_list(:order, 2, customer_id: customer_id) }
      let!(:other_orders) { create_list(:order, 2) }

      before { get "/api/v1/orders?customer_id=#{customer_id}" }

      it "returns filtered orders" do
        json_response = JSON.parse(response.body)
        orders = json_response["orders"]
        expect(orders.size).to eq(2)
        expect(orders).to all(include("customer_id" => customer_id))
      end
    end
  end

  describe "GET /api/v1/orders/:id" do
    context "when order exists" do
      let(:order) { create(:order) }

      before do
        allow_any_instance_of(Customers::FetcherService).to receive(:call)
          .and_return(double(
            success?: true,
            customer_data: { id: 1, name: "Test Customer", email: "test@example.com" }
          ))

        get "/api/v1/orders/#{order.id}"
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct order" do
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(order.id)
      end

      it "includes customer data" do
        json_response = JSON.parse(response.body)
        expect(json_response["customer"]).to be_present
        expect(json_response["customer"]["name"]).to eq("Test Customer")
      end
    end

    context "when order does not exist" do
      before { get "/api/v1/orders/0" }

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/orders" do
    let(:valid_attributes) do
      {
        order: {
          customer_id: 1,
          product_name: "Test Product",
          quantity: 2,
          price: 100.0,
          status: "pending"
        }
      }
    end

    let(:invalid_attributes) do
      {
        order: {
          product_name: "Test"
        }
      }
    end

    context "with valid parameters" do
      before do
        mock_result = double(
          success?: true,
          order: create(:order),
          customer_data: { id: 1, name: "Test Customer" }
        )

        allow_any_instance_of(Orders::CreatorService).to receive(:call)
          .and_return(mock_result)

        post "/api/v1/orders", params: valid_attributes
      end

      it "returns created status" do
        expect(response).to have_http_status(:created)
      end

      it "returns success message" do
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Order created successfully")
      end

      it "returns order and customer data" do
        json_response = JSON.parse(response.body)
        expect(json_response).to include("order", "customer")
      end
    end

    context "with invalid parameters" do
      before do
        mock_result = double(
          success?: false,
          error_type: "validation_error",
          error_message: "Invalid parameters",
          errors: [ "Customer id can't be blank" ],
          status_code: :unprocessable_entity
        )

        allow_any_instance_of(Orders::CreatorService).to receive(:call)
          .and_return(mock_result)

        post "/api/v1/orders", params: invalid_attributes
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error details" do
        json_response = JSON.parse(response.body)
        expect(json_response).to include("error", "message", "details")
      end
    end
  end
end
