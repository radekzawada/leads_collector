module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_key!
  end

  private

  def authenticate_api_key!
    provided = request.headers["X-API-Key"]
    expected = ENV["API_KEY"]

    unless expected.present? && provided.present? &&
           ActiveSupport::SecurityUtils.secure_compare(provided, expected)
      head :unauthorized
    end
  end
end
