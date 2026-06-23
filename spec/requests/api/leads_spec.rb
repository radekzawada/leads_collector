require "rails_helper"

RSpec.describe "POST /api/leads" do
  subject(:create) { post path, **request_options; response }

  let(:path) { "/api/leads" }
  let(:api_key) { "test-api-key" }
  let(:headers) { json_headers(api_key: api_key) }
  let(:payload) do
    {
      source: "facebook",
      group_name: "Noclegi Karkonosze",
      post_url: "https://facebook.com/groups/example/posts/1",
      post_text: "Szukam noclegu dla 2+2 w Szklarskiej Porębie",
      posted_at: "2026-06-23T10:30:00+02:00",
      is_lead: true,
      date_from: "2026-08-15",
      date_to: "2026-08-18",
      adults: 2,
      children: 2,
      guests_total: 4,
      location: "Szklarskiej Porębie"
    }
  end
  let(:request_options) { { params: payload.to_json, headers: headers } }
  let(:missing_request_options) { { params: payload.to_json, headers: { "Content-Type" => "application/json" } } }
  let(:invalid_request_options) { { params: payload.to_json, headers: json_headers(api_key: "wrong-key") } }

  before { stub_service_env(api_key: api_key) }

  it_behaves_like "requires API key", :create

  context "with valid API key" do
    context "when lead is available" do
      before { allow(AvailabilityChecker).to receive(:call).and_return(:available) }

      context "when Telegram notification is stubbed" do
        before { allow(TelegramNotifier).to receive(:call).and_return(true) }

        it "creates a lead" do
          expect { create }.to change(Lead, :count).by(1)

          expect(create).to have_http_status(:created)
          expect(create.parsed_body["is_lead"]).to be(true)
          expect(create.parsed_body["availability_status"]).to eq("available")
          expect(create.parsed_body["adults"]).to eq(2)
          expect(create.parsed_body["location"]).to eq("Szklarskiej Porębie")
        end
      end

      context "when sending Telegram notification" do
        let(:telegram_stub) do
          stub_request(:post, "https://api.telegram.org/bottest-token/sendMessage")
            .to_return(status: 200, body: { ok: true }.to_json)
        end

        before { telegram_stub }

        it "sends a Telegram notification" do
          expect(create.parsed_body["notification_sent_at"]).to be_present
          expect(telegram_stub).to have_been_requested
        end
      end
    end

    context "when date range is provided in request" do
      let(:payload) do
        {
          source: "facebook",
          group_name: "Noclegi Karkonosze",
          post_url: "https://facebook.com/groups/example/posts/explicit-dates",
          post_text: "Szukam noclegu w Szklarskiej Porębie",
          posted_at: "2026-06-23T10:30:00+02:00",
          is_lead: true,
          date_from: "2026-07-07",
          date_to: "2026-07-10",
          location: "Szklarskiej Porębie"
        }
      end

      before do
        allow(AvailabilityChecker).to receive(:call).and_return(:available)
        allow(TelegramNotifier).to receive(:call).and_return(true)
      end

      it "stores dates from request and checks availability" do
        expect(create).to have_http_status(:created)
        expect(create.parsed_body["date_from"]).to eq("2026-07-07")
        expect(create.parsed_body["date_to"]).to eq("2026-07-10")
        expect(AvailabilityChecker).to have_received(:call).with(
          date_from: Date.new(2026, 7, 7),
          date_to: Date.new(2026, 7, 10)
        )
      end
    end

    context "when lead has no dates" do
      let(:payload) do
        {
          source: "facebook",
          group_name: "Noclegi Karkonosze",
          post_url: "https://facebook.com/groups/example/posts/no-dates",
          post_text: "Szukam noclegu w Szklarskiej Porębie",
          posted_at: "2026-06-23T10:30:00+02:00",
          is_lead: true,
          location: "Szklarskiej Porębie"
        }
      end
      let(:telegram_stub) do
        stub_request(:post, "https://api.telegram.org/bottest-token/sendMessage")
          .to_return(status: 200, body: { ok: true }.to_json)
      end

      before do
        allow(AvailabilityChecker).to receive(:call)
        telegram_stub
      end

      it "sends a notification without checking availability" do
        expect(create).to have_http_status(:created)
        expect(create.parsed_body["is_lead"]).to be(true)
        expect(create.parsed_body["availability_status"]).to eq("unknown")
        expect(create.parsed_body["notification_sent_at"]).to be_present
        expect(AvailabilityChecker).not_to have_received(:call)
        expect(telegram_stub).to have_been_requested
      end
    end

    context "when is_lead is false" do
      let(:payload) do
        {
          source: "facebook",
          group_name: "Noclegi Karkonosze",
          post_url: "https://facebook.com/groups/example/posts/not-a-lead",
          post_text: "Piękna pogoda w Karpaczu dzisiaj!",
          posted_at: "2026-06-23T12:00:00+02:00",
          is_lead: false
        }
      end
      let(:telegram_stub) do
        stub_request(:post, %r{https://api\.telegram\.org/bot.*/sendMessage})
          .to_return(status: 200, body: { ok: true }.to_json)
      end

      before { telegram_stub }

      it "does not send a notification" do
        expect(create).to have_http_status(:created)
        expect(create.parsed_body["is_lead"]).to be(false)
        expect(create.parsed_body["notification_sent_at"]).to be_nil
        expect(telegram_stub).not_to have_been_requested
      end
    end

    context "when dates are unavailable" do
      let(:telegram_stub) do
        stub_request(:post, %r{https://api\.telegram\.org/bot.*/sendMessage})
          .to_return(status: 200, body: { ok: true }.to_json)
      end

      before do
        allow(AvailabilityChecker).to receive(:call).and_return(:unavailable)
        telegram_stub
      end

      it "does not send a notification" do
        expect(create).to have_http_status(:created)
        expect(create.parsed_body["availability_status"]).to eq("unavailable")
        expect(create.parsed_body["notification_sent_at"]).to be_nil
        expect(telegram_stub).not_to have_been_requested
      end
    end

    context "when post_url already exists" do
      before do
        allow(AvailabilityChecker).to receive(:call).and_return(:available)
        allow(TelegramNotifier).to receive(:call).and_return(true)
      end

      let!(:existing_lead) do
        post path, params: payload.to_json, headers: headers
        Lead.last
      end

      it "does not create a duplicate lead" do
        expect { create }.not_to change(Lead, :count)

        expect(create).to have_http_status(:ok)
        expect(create.parsed_body["post_url"]).to eq(payload[:post_url])
      end
    end
  end
end
