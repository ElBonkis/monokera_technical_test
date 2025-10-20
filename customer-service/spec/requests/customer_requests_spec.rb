require 'rails_helper'

RSpec.describe "Api::V1::Customers", type: :request do
  describe "GET /api/v1/customers" do
    let!(:customers) { create_list(:customer, 3) }

    before { get "/api/v1/customers" }

    it "returns success status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all customers" do
      json_response = JSON.parse(response.body)
      expect(json_response["customers"].size).to eq(3)
    end

    it "returns customers with correct attributes" do
      json_response = JSON.parse(response.body)
      expect(json_response["customers"].first).to include(
        "id",
        "name",
        "email",
        "address",
        "phone",
        "orders_count"
      )
    end
  end

  describe "GET /api/v1/customers/:id" do
    context "when customer exists" do
      let(:customer) { create(:customer) }

      before { get "/api/v1/customers/#{customer.id}" }

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct customer" do
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(customer.id)
        expect(json_response["name"]).to eq(customer.name)
        expect(json_response["email"]).to eq(customer.email)
      end

      it "includes orders count" do
        json_response = JSON.parse(response.body)
        expect(json_response["orders_count"]).to eq(customer.orders_count)
      end
    end

    context "when customer does not exist" do
      before { get "/api/v1/customers/99999" }

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response).to include("error", "message")
      end
    end
  end

  describe "POST /api/v1/customers" do
    let(:valid_attributes) do
      {
        customer: {
          name: "John Doe",
          email: "john.unique#{rand(1000)}@example.com",
          address: "123 Main St",
          phone: "+57 300 123 4567"
        }
      }
    end

    context "with valid parameters" do
      it "returns created status" do
        post "/api/v1/customers", params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "creates a new customer" do
        expect {
          post "/api/v1/customers", params: valid_attributes
        }.to change(Customer, :count).by(1)
      end

      it "returns serialized customer data" do
        post "/api/v1/customers", params: valid_attributes
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          "id",
          "name",
          "email",
          "address",
          "phone",
          "orders_count"
        )
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          customer: {
            name: "",
            email: "invalid"
          }
        }
      end

      it "returns unprocessable entity status" do
        post "/api/v1/customers", params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error details" do
        post "/api/v1/customers", params: invalid_attributes
        json_response = JSON.parse(response.body)
        expect(json_response).to include("error", "message")
      end
    end
  end
end
