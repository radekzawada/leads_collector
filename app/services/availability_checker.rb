class AvailabilityChecker
  def self.call(date_from:, date_to:)
    new(date_from:, date_to:).call
  end

  def initialize(date_from:, date_to:)
    @date_from = date_from
    @date_to = date_to
  end

  def call
    return :invalid_dates if invalid_dates?

    events = fetch_events
    return :unknown if events.nil?

    events.any? { |event_start, event_end| overlaps?(event_start, event_end) } ? :unavailable : :available
  rescue StandardError => e
    Rails.logger.warn("AvailabilityChecker failed: #{e.message}")
    :unknown
  end

  private

  attr_reader :date_from, :date_to

  def invalid_dates?
    date_from.blank? || date_to.blank? || date_from >= date_to
  end

  def fetch_events
    url = ENV["BEDBOOKING_ICAL_URL"]
    return nil if url.blank?

    response = Faraday.get(url)
    return nil unless response.success?

    calendars = Icalendar::Calendar.parse(response.body)
    calendars.flat_map { |calendar| calendar.events.map { |event| event_range(event) } }.compact
  end

  def event_range(event)
    start_date = event.dtstart.to_date
    end_date = event.dtend&.to_date || start_date + 1.day
    [ start_date, end_date ]
  end

  def overlaps?(event_start, event_end)
    date_from < event_end && date_to > event_start
  end
end
