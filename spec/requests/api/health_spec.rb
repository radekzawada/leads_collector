require "rails_helper"

RSpec.describe "GET /api/health" do
  subject(:show) { get path, **request_options; response }

  let(:path) { "/api/health" }
  let(:headers) { json_headers }
  let(:request_options) { { headers: headers } }
  let(:missing_request_options) { { headers: {} } }
  let(:invalid_request_options) { { headers: json_headers(api_key: "wrong-key") } }

  before { stub_api_authentication }

  it_behaves_like "requires API key", :show

  context "with valid API key" do
    it "returns ok status" do
      expect(show).to have_http_status(:ok)
      expect(show.parsed_body).to eq("status" => "ok")
    end
  end
end
