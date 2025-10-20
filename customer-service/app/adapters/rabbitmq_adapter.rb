require 'bunny'

class RabbitmqAdapter < MessageBrokerAdapter::Base
  attr_reader :connection, :channel, :exchange

  def initialize(url: nil, exchange_name: 'orders.events')
    @url = url || ENV.fetch('RABBITMQ_URL', 'amqp://admin:admin@localhost:5672')
    @exchange_name = exchange_name
    setup_connection
  end

  def publish(routing_key, message)
    payload = message.is_a?(String) ? message : message.to_json
    @exchange.publish(payload, routing_key: routing_key, persistent: true, content_type: 'application/json')
    Rails.logger.info "[RabbitMQ] Published to '#{routing_key}'"
    true
  rescue => e
    Rails.logger.error "[RabbitMQ] Publish failed: #{e.message}"
    raise
  end

  def subscribe(routing_key, queue_name: nil, &block)
    queue_name ||= "#{Rails.application.class.module_parent_name.underscore}.#{routing_key.gsub('.', '_')}"
    queue = @channel.queue(queue_name, durable: true)
    queue.bind(@exchange, routing_key: routing_key)

    Rails.logger.info "[RabbitMQ] Subscribed to '#{routing_key}'"

    queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, body|
      begin
        message = JSON.parse(body)
        yield(message, delivery_info, properties)
        @channel.ack(delivery_info.delivery_tag)
      rescue => e
        Rails.logger.error "Error: #{e.message}"
        @channel.nack(delivery_info.delivery_tag, false, !delivery_info.redelivered)
      end
    end
  end

  def close
    @channel&.close
    @connection&.close
    Rails.logger.info "[RabbitMQ] Closed"
  end

  def connected?
    @connection&.open? && @channel&.open?
  end

  private

  def setup_connection
    @connection = Bunny.new(@url, automatically_recover: true)
    @connection.start
    @channel = @connection.create_channel
    @exchange = @channel.topic(@exchange_name, durable: true)
    Rails.logger.info "[RabbitMQ] Connected"
  rescue => e
    Rails.logger.error "Connection failed: #{e.message}"
    raise
  end
end
