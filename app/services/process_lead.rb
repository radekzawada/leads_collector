class ProcessLead
  Result = Struct.new(:lead, :created, keyword_init: true)

  def self.call(attributes)
    new(attributes).call
  end

  def initialize(attributes)
    @attributes = attributes
  end

  def call
    existing = find_existing
    return result(existing, created: false) if existing

    lead = Lead.create!(raw_attributes)
    apply_extraction(lead)
    check_availability_and_notify(lead)
    result(lead, created: true)
  rescue ActiveRecord::RecordNotUnique
    existing = find_existing
    raise unless existing

    result(existing, created: false)
  end

  private

  attr_reader :attributes

  def find_existing
    post_url = attributes[:post_url]
    return if post_url.blank?

    Lead.find_by(post_url: post_url)
  end

  def result(lead, created:)
    Result.new(lead: lead, created: created)
  end

  def raw_attributes
    attributes.slice(:source, :group_name, :post_url, :post_text, :posted_at, :date_from, :date_to)
  end

  def apply_extraction(lead)
    extraction = LeadExtractor.call(post_text: lead.post_text)
    confidence = extraction[:confidence]
    confidence += 0.25 if attributes[:date_from].present? && attributes[:date_to].present?
    lead.update!(
      is_lead: extraction[:is_lead],
      adults: extraction[:adults],
      children: extraction[:children],
      guests_total: extraction[:guests_total],
      location: extraction[:location],
      confidence: [ confidence, 1.0 ].min.round(4),
      raw_extraction: extraction[:raw]
    )
  rescue StandardError => e
    Rails.logger.warn("Lead extraction failed: #{e.message}")
  end

  def check_availability_and_notify(lead)
    return unless lead.is_lead?

    if lead.date_from.present? && lead.date_to.present?
      status = AvailabilityChecker.call(date_from: lead.date_from, date_to: lead.date_to)
      lead.update!(availability_status: status.to_s)
      return unless status == :available
    end

    return unless TelegramNotifier.call(lead: lead)

    lead.update!(notification_sent_at: Time.current)
  rescue StandardError => e
    Rails.logger.warn("Availability check failed: #{e.message}")
  end
end
