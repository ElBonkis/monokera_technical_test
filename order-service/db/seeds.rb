puts "Cleaning existing data"
Order.destroy_all

puts "Resetting ID sequence"
ActiveRecord::Base.connection.reset_pk_sequence!('orders')

puts "Seeding orders using Orders::Creator service..."
puts "(This will trigger RabbitMQ events and update customer counters)\n\n"

products = [
  { name: "Laptop HP Pavilion 15", price: 2_500_000 },
  { name: "iPhone 14 Pro", price: 4_500_000 },
  { name: "Samsung Galaxy S23", price: 3_200_000 },
  { name: "MacBook Air M2", price: 5_800_000 },
  { name: "iPad Pro 12.9", price: 4_200_000 },
  { name: "AirPods Pro", price: 850_000 },
  { name: "Apple Watch Series 8", price: 2_100_000 },
  { name: "Sony WH-1000XM5", price: 1_200_000 },
  { name: "Dell XPS 13", price: 4_800_000 },
  { name: "Nintendo Switch OLED", price: 1_500_000 },
  { name: "PlayStation 5", price: 2_800_000 },
  { name: "Canon EOS R6", price: 12_500_000 },
  { name: "DJI Mini 3 Pro", price: 3_500_000 },
  { name: "Monitor LG UltraWide 34", price: 1_800_000 },
  { name: "Teclado Mecánico Logitech", price: 450_000 }
]

statuses = ['pending', 'processing', 'completed']

customer_ids = (1..10).to_a

puts "  IMPORTANT NOTES:"
puts "   1. Make sure Customer Service is running on port 3001"
puts "   2. Make sure RabbitMQ is running"
puts "   3. Make sure you have customers with IDs: #{customer_ids.join(', ')}"
puts "   4. Run 'cd customer_service && bin/rails db:seed' first if needed"
puts "   5. Make sure the RabbitMQ listener is running: 'cd customer_service && bundle exec rake rabbitmq:listen'"
puts ""
puts "   Press Enter to continue or Ctrl+C to cancel..."

created_orders = []
failed_orders = []

30.times do |i|
  product = products.sample
  customer_id = customer_ids.sample

  order_params = {
    customer_id: customer_id,
    product_name: product[:name],
    quantity: rand(1..5),
    price: product[:price],
    status: statuses.sample
  }

  print "  Creating order #{i + 1}/30: #{product[:name]} for Customer ##{customer_id}... "

  begin
    result = Orders::CreatorService.call(order_params)

    if result.success?
      created_orders << result.order
      puts "(Order ##{result.order.id})"

      sleep(0.1)
    else
      failed_orders << { params: order_params, error: result.error_message }
      puts "Failed: #{result.error_message}"
    end
  rescue => e
    failed_orders << { params: order_params, error: e.message }
    puts "Error: #{e.message}"
  end
end

puts "\n" + "=" * 70
puts " Seeding Summary:"
puts "=" * 70
puts "  Successfully created: #{created_orders.count} orders"
puts "  Failed: #{failed_orders.count} orders"
puts ""
puts "  Total orders in database: #{Order.count}"

if created_orders.any?
  puts "\n  Orders by status:"
  Order.group(:status).count.each do |status, count|
    puts "    #{status}: #{count}"
  end
  
  puts "\n  Orders by customer:"
  Order.group(:customer_id).count.sort.each do |customer_id, count|
    puts "    Customer ##{customer_id}: #{count} orders"
  end
end

if failed_orders.any?
  puts "\n  Failed orders details:"
  failed_orders.each_with_index do |failed, index|
    puts "    #{index + 1}. Customer ##{failed[:params][:customer_id]} - #{failed[:error]}"
  end
end

puts "\n" + "=" * 70
puts " Order Service seeds completed!"
puts "=" * 70
puts ""
puts " Next steps:"
puts "   1. Check RabbitMQ listener logs for event processing"
puts "   2. Verify customer orders_count updated:"
puts "      curl http://localhost:3001/api/v1/customers/1 | jq '.orders_count'"
puts "   3. Check Solid Queue for job execution:"
puts "      cd order_service && bin/rails console"
puts "      SolidQueue::Job.where(class_name: 'PublishOrderEventJob').count"
