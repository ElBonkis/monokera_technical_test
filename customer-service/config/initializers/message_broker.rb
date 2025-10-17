Rails.application.config.to_prepare do
  begin
    MessageBroker = MessageBrokerFactory.create(:rabbitmq)
    Rails.logger.info "MessageBroker initialized for Customer Service"
  rescue => e
    Rails.logger.error "Failed to initialize MessageBroker: #{e.message}"
    if Rails.env.development?
      Rails.logger.warn "Running without MessageBroker (development mode)"
      MessageBroker = nil
    else
      raise
    end
  end
end
