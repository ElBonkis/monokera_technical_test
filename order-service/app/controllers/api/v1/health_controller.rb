class HealthController < ApplicationController
  def show
    render json: {
      status: 'ok',
      service: service_name,
      timestamp: Time.current.iso8601,
      checks: {
        database: database_check,
        rabbitmq: rabbitmq_check
      }
    }, status: :ok
  rescue => e
    render json: {
      status: 'error',
      message: e.message
    }, status: :service_unavailable
  end

  private

  def service_name
    Rails.application.class.module_parent_name.underscore.humanize
  end

  def database_check
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue
    'disconnected'
  end

  def rabbitmq_check
    MessageBroker&.connected? ? 'connected' : 'disconnected'
  rescue
    'disconnected'
  end
end
