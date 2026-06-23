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
      Termin: #{date_range}
      Osoby: #{guests_summary}
      Lokalizacja: #{lead.location}
      Dostępność: #{availability_label}

      Treść:
      #{lead.post_text}

      Link:
      #{lead.post_url}
    MESSAGE
  end

  def date_range
    return "brak dat" unless lead.date_from.present? && lead.date_to.present?

    "#{lead.date_from} – #{lead.date_to}"
  end

  def guests_summary
    return "nieznana" if lead.guests_total.blank?

    "#{lead.guests_total} (#{lead.adults || 0} dorosłych, #{lead.children || 0} dzieci)"
  end

  def availability_label
    return "✅ wolne" if lead.availability_status == "available"

    "nie sprawdzono"
  end
end
