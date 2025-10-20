class ProcessOrderEventJob < ApplicationJob
  queue_as :events

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(event_data)
    Rails.logger.info "Processing event: #{event_data['event_type']}"

    OrderListener.new.process_event(event_data)
  end
end
