Rails.application.config.to_prepare do
  MessageBroker = MessageBrokerFactory.create(:rabbitmq)
end