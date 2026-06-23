class TelegramNotifier
  def self.call(lead:)
    new(lead).call
  end

  def initialize(lead)
    @lead = lead
  end

  def call
    token = ENV["TELEGRAM_BOT_TOKEN"]
    chat_id = ENV["TELEGRAM_CHAT_ID"]
    return false if token.blank? || chat_id.blank?

    response = Faraday.post(
      "https://api.telegram.org/bot#{token}/sendMessage",
      { chat_id: chat_id, text: message }
    )

    response.success?
  rescue StandardError => e
    Rails.logger.warn("TelegramNotifier failed: #{e.message}")
    false
  end

  private

  attr_reader :lead

  def message
    <<~MESSAGE.strip
      🔥 Nowy lead noclegowy

      Grupa: #{lead.group_name}
      Termin: #{lead.date_from} – #{lead.date_to}
      Osoby: #{lead.guests_total} (#{lead.adults} dorosłych, #{lead.children} dzieci)
      Lokalizacja: #{lead.location}
      Dostępność: ✅ wolne

      Treść:
      #{lead.post_text}

      Link:
      #{lead.post_url}
    MESSAGE
  end
end
