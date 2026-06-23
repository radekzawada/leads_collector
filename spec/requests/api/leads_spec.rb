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
      post_text: "Szukam noclegu dla 2+2 od 15 do 18 sierpnia w Szklarskiej Porębie",
      posted_at: "2026-06-23T10:30:00+02:00"
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
