require "rails_helper"

RSpec.describe AvailabilityChecker do
  describe ".call" do
    subject(:call) { described_class.call(date_from: date_from, date_to: date_to) }

    let(:ical_url) { "https://example.com/calendar.ics" }
    let(:date_from) { Date.new(2026, 8, 15) }
    let(:date_to) { Date.new(2026, 8, 18) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BEDBOOKING_ICAL_URL").and_return(ical_url)
    end

    context "when dates are missing" do
      let(:date_from) { nil }

      it { expect(call).to eq(:invalid_dates) }
    end

    context "when date_from is after date_to" do
      let(:date_from) { Date.new(2026, 8, 18) }
      let(:date_to) { Date.new(2026, 8, 15) }

      it { expect(call).to eq(:invalid_dates) }
    end

    context "when calendar is empty" do
      before do
        stub_request(:get, ical_url).to_return(
          status: 200,
          body: file_fixture("empty_calendar.ics").read
        )
      end

      it { expect(call).to eq(:available) }
    end

    context "when booking overlaps stay" do
      before do
        stub_request(:get, ical_url).to_return(
          status: 200,
          body: file_fixture("booking.ics").read
        )
      end

      it { expect(call).to eq(:unavailable) }
    end
  end
end
