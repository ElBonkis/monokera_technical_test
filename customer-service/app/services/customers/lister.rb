class Customers::Lister < ApplicationService
  def call
    customers = Customer.recent

    {
      customers: customers.map { |c| CustomerSerializer.new(c).as_json },
      total: customers.count
    }
  end
end
