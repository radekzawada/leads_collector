class LeadExtractor
  LEAD_KEYWORDS = %w[szukam nocleg noclegu pokój pokoju mieszkanie kwatera kwatery].freeze

  LOCATIONS = [
    "Szklarska Poręba", "Szklarskiej Porębie",
    "Karpacz", "Karpaczu",
    "Karkonosze", "Karkonoszach",
    "Jelenia Góra", "Jeleniej Górze",
    "Świeradów", "Świeradowie"
  ].freeze

  def self.call(post_text:)
    new(post_text).call
  end

  def initialize(post_text)
    @post_text = post_text.to_s
    @normalized = @post_text.downcase
  end

  def call
    {
      is_lead: lead?,
      adults: adults,
      children: children,
      guests_total: guests_total,
      location: location,
      confidence: confidence,
      raw: raw_details
    }
  end

  private

  attr_reader :post_text, :normalized

  def lead?
    LEAD_KEYWORDS.any? { |keyword| normalized.include?(keyword) }
  end

  def plus_match
    @plus_match ||= normalized.match(/(\d+)\s*\+\s*(\d+)/)
  end

  def adults
    return plus_match[1].to_i if plus_match

    osob_match = normalized.match(/(\d+)\s+osób/)
    return osob_match[1].to_i if osob_match

    doroslych_match = normalized.match(/(\d+)\s+dorosłych/)
    doroslych_match&.[](1)&.to_i
  end

  def children
    return plus_match[2].to_i if plus_match

    dzieci_match = normalized.match(/(\d+)\s+dzieci/)
    dzieci_match&.[](1)&.to_i
  end

  def guests_total
    return adults + children if adults && children

    adults || children
  end

  def location
    LOCATIONS.find { |name| normalized.include?(name.downcase) }
  end

  def confidence
    score = 0.0
    score += 0.3 if lead?
    score += 0.2 if guests_total
    score += 0.15 if location
    score += 0.1 if plus_match
    [ score, 1.0 ].min.round(4)
  end

  def raw_details
    {
      matched_keywords: LEAD_KEYWORDS.select { |keyword| normalized.include?(keyword) },
      guest_pattern: plus_match&.to_s,
      location_match: location
    }
  end
end
