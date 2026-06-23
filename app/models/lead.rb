class Lead < ApplicationRecord
  AVAILABILITY_STATUSES = %w[unknown available unavailable invalid_dates].freeze

  validates :post_text, presence: true
  validates :post_url, uniqueness: true, allow_blank: true
  validates :availability_status, inclusion: { in: AVAILABILITY_STATUSES }
end
