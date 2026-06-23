module AuthenticationHelpers
  def json_headers(api_key: "test-api-key")
    {
      "X-API-Key" => api_key,
      "Content-Type" => "application/json"
    }
  end

  def stub_api_authentication(api_key: "test-api-key")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("API_KEY").and_return(api_key)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers
end
