class CustomerSerializer
  def initialize(customer)
    @customer = customer
  end

  def as_json
    {
      id: @customer.id,
      name: @customer.name,
      email: @customer.email,
      address: @customer.address,
      phone: @customer.phone,
      orders_count: @customer.orders_count,
      created_at: @customer.created_at
    }
  end
end
