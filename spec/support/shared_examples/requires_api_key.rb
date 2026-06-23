RSpec.shared_examples "requires API key" do |action|
  context "when API key is missing" do
    let(:request_options) { missing_request_options }

    it { expect(public_send(action)).to have_http_status(:unauthorized) }
  end

  context "when API key is invalid" do
    let(:request_options) { invalid_request_options }

    it { expect(public_send(action)).to have_http_status(:unauthorized) }
  end
end
