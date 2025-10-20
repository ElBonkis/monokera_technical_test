namespace :rabbitmq do
  desc "Start RabbitMQ listener for order events"
  task listen: :environment do
    puts "=" * 70
    puts "RabbitMQ Order Event Listener - Customer Service"
    puts "=" * 70
    puts "Environment:     #{Rails.env}"
    puts "RabbitMQ URL:    #{ENV.fetch('RABBITMQ_URL', 'default')}"
    puts "Listening:       order.created events"
    puts "Queue:           customer_service.orders"
    puts "=" * 70
    puts "Press Ctrl+C to stop"
    puts ""

    begin
      MessageBroker.subscribe('order.created', queue_name: 'customer_service.orders') do |message, delivery_info, properties|
        Rails.logger.info "Received order.created event"
        Events::OrderListener.call(message)
      end
    rescue Interrupt
      puts "\n" + "=" * 70
      puts "Listener stopped gracefully"
      puts "=" * 70
      MessageBroker&.close
      exit 0
    rescue => e
      puts "\n" + "=" * 70
      puts "Fatal error: #{e.message}"
      puts e.backtrace.first(10).join("\n")
      puts "=" * 70
      exit 1
    end
  end

  desc "Test RabbitMQ connection"
  task test: :environment do
    puts "Testing RabbitMQ connection..."

    if MessageBroker&.connected?
      puts "RabbitMQ is connected!"
      puts "Exchange: #{MessageBroker.exchange.name}"
      puts "Channel: #{MessageBroker.channel.id}"
    else
      puts "RabbitMQ is not connected!"
      exit 1
    end
  end
end