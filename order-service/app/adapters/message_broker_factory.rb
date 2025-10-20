class MessageBrokerFactory
  ADAPTERS = { rabbitmq: RabbitmqAdapter }.freeze

  def self.create(type = :rabbitmq, **options)
    adapter_class = ADAPTERS[type.to_sym]
    raise ArgumentError, "Unknown broker type: #{type}" unless adapter_class
    adapter_class.new(**options)
  end

  def self.available_adapters
    ADAPTERS.keys
  end
end