if defined?(Rack::Timeout)
  if Rack::Timeout.respond_to?(:service_timeout=)
    Rack::Timeout.service_timeout = ENV.fetch("RACK_TIMEOUT_SERVICE_TIMEOUT", 10).to_i
  end
  if Rack::Timeout.respond_to?(:wait_timeout=)
    Rack::Timeout.wait_timeout = ENV.fetch("RACK_TIMEOUT_WAIT_TIMEOUT", 15).to_i
  end
end
