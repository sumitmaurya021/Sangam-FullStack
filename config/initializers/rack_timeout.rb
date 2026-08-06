# Configure Rack::Timeout to protect Puma worker threads from long-running HTTP requests (e.g. external LLM calls)
if defined?(Rack::Timeout)
  Rack::Timeout.service_timeout = ENV.fetch("RACK_TIMEOUT_SERVICE_TIMEOUT", 10).to_i
  Rack::Timeout.wait_timeout    = ENV.fetch("RACK_TIMEOUT_WAIT_TIMEOUT", 15).to_i
end
