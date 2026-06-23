require "rails_helper"

RSpec.describe LeadExtractor do
  describe ".call" do
    subject(:call) { described_class.call(post_text: post_text) }

    context "when post is accommodation search" do
      let(:post_text) do
        "Szukam noclegu dla 2+2 od 15 do 18 sierpnia w Szklarskiej Porębie"
      end

      it { expect(call[:is_lead]).to be(true) }
      it { expect(call[:date_from]).to eq(Date.new(2026, 8, 15)) }
      it { expect(call[:date_to]).to eq(Date.new(2026, 8, 18)) }
      it { expect(call[:adults]).to eq(2) }
      it { expect(call[:children]).to eq(2) }
      it { expect(call[:guests_total]).to eq(4) }
      it { expect(call[:location]).to eq("Szklarskiej Porębie") }
      it { expect(call[:confidence]).to be > 0.5 }
    end

    context "when post is unrelated" do
      let(:post_text) { "Sprzedam rower górski w dobrym stanie" }

      it { expect(call[:is_lead]).to be(false) }
      it { expect(call[:date_from]).to be_nil }
      it { expect(call[:date_to]).to be_nil }
    end
  end
end
