module EnvHelpers
  def stub_service_env(
    api_key: "test-api-key",
    ical_url: "https://example.com/calendar.ics",
    telegram_token: "test-token",
    telegram_chat_id: "123456"
  )
    stub_api_authentication(api_key: api_key)
    allow(ENV).to receive(:[]).with("BEDBOOKING_ICAL_URL").and_return(ical_url)
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return(telegram_token)
    allow(ENV).to receive(:[]).with("TELEGRAM_CHAT_ID").and_return(telegram_chat_id)
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
