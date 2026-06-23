if Rails.env.production? && ENV["API_KEY"].blank?
  raise "API_KEY environment variable is required in production"
end
