class CustomerServiceClient
  class ConnectionError < StandardError; end
  class NotFoundError < StandardError; end
  class ServerError < StandardError; end

  def initialize
    @base_url = ENV.fetch('CUSTOMER_SERVICE_URL', 'http://localhost:3001')
    @timeout = 5
    @conn = build_connection
  end

  def get_customer(customer_id)
    response = @conn.get("/api/v1/customers/#{customer_id}")
    handle_response(response)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    Rails.logger.error "Connection failed: #{e.message}"
    raise ConnectionError, "Unable to connect to Customer Service"
  end

  private

  def build_connection
    Faraday.new(url: @base_url) do |f|
      f.request :json
      f.request :retry,
        max: 3,
        interval: 0.5,
        backoff_factor: 2,
        exceptions: [ Faraday::TimeoutError ]
      f.response :json, content_type: /\bjson$/
      f.options.timeout = @timeout
      f.options.open_timeout = 2
      f.adapter Faraday.default_adapter
    end
  end

  def handle_response(response)
    case response.status
    when 200
      response.body
    when 404
      Rails.logger.warn "Customer not found"
      nil
    when 500..599
      raise ServerError, "Customer Service internal error: #{response.status}"
    else
      raise CustomerServiceError, "Unexpected response: #{response.status}"
    end
  end
end

class CustomerServiceError < StandardError; end
