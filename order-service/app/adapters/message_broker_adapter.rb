module MessageBrokerAdapter
  class Base
    def publish(routing_key, message)
      raise NotImplementedError, "#{self.class} must implement #publish"
    end

    def subscribe(routing_key, queue_name: nil, &block)
      raise NotImplementedError, "#{self.class} must implement #subscribe"
    end

    def close
      raise NotImplementedError, "#{self.class} must implement #close"
    end

    def connected?
      raise NotImplementedError, "#{self.class} must implement #connected?"
    end
  end
end