Order.destroy_all if Rails.env.development?

puts "Seeding orders"

sample_orders = [
  { customer_id: 1, product_name: 'Laptop HP', quantity: 1, price: 2500000, status: 'completed' },
  { customer_id: 1, product_name: 'Mouse Logitech', quantity: 2, price: 50000, status: 'completed' },
  { customer_id: 2, product_name: 'Teclado Mecánico', quantity: 1, price: 350000, status: 'processing' },
  { customer_id: 3, product_name: 'Monitor Samsung', quantity: 1, price: 800000, status: 'pending' },
]

sample_orders.each do |order_data|
  order = Order.create!(order_data)
  puts "Created order: #{order.product_name} for Customer ##{order.customer_id}"
end

puts "Seeding completed! Created #{Order.count} orders"