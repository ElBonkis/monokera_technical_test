class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked
  discard_on ActiveJob::DeserializationError

  before_perform do |job|
    Rails.logger.info "Starting job: #{job.class.name}"
  end

  after_perform do |job|
    Rails.logger.info "Completed job: #{job.class.name}"
  end

  rescue_from(StandardError) do |exception|
    Rails.logger.error "Job failed: #{self.class.name}"
    Rails.logger.error "Error: #{exception.message}"
    raise exception
  end
end