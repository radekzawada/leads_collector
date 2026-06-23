FactoryBot.define do
  factory :lead do
    source { "facebook" }
    group_name { "Noclegi Karkonosze" }
    post_url { "https://facebook.com/groups/example/posts/1" }
    post_text { "Szukam noclegu dla 2+2 od 15 do 18 sierpnia w Szklarskiej Porębie" }
    posted_at { Time.zone.parse("2026-06-23T10:30:00+02:00") }
    is_lead { true }
    date_from { Date.new(2026, 8, 15) }
    date_to { Date.new(2026, 8, 18) }
    adults { 2 }
    children { 2 }
    guests_total { 4 }
    location { "Szklarskiej Porębie" }
    confidence { 0.85 }
    availability_status { "unknown" }
    raw_extraction { {} }
  end
end
