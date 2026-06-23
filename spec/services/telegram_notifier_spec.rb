require "rails_helper"

RSpec.describe TelegramNotifier do
  describe ".call" do
    subject(:call) { described_class.call(lead: lead) }

    let(:lead) { build(:lead) }
    let(:token) { "test-telegram-token" }
    let(:chat_id) { "123456789" }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return(token)
      allow(ENV).to receive(:[]).with("TELEGRAM_CHAT_ID").and_return(chat_id)
    end

    context "when Telegram API succeeds" do
      before do
        stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
          .to_return(status: 200, body: { ok: true }.to_json)
      end

      it { expect(call).to be(true) }

      it "includes group name in message" do
        call

        expect(WebMock).to have_requested(:post, "https://api.telegram.org/bot#{token}/sendMessage")
          .with { |request| URI.decode_www_form(request.body).to_h["text"].include?("Noclegi Karkonosze") }
      end
    end

    context "when Telegram API fails" do
      before do
        stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
          .to_return(status: 500, body: "error")
      end

      it { expect(call).to be(false) }
    end
  end
end
