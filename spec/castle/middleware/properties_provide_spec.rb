# frozen_string_literal: true

describe Castle::Middleware::PropertiesProvide do
  describe '::call' do
    subject(:result) { described_class.call(req_params, prop_map) }

    let(:req_params) { { 'user.email' => 'testing', 'user.name' => 'John Doe' } }

    context 'when no properties defined in map' do
      let(:prop_map) { {} }

      it { is_expected.to be_empty }
    end

    context 'when properties contains key that matches request params' do
      let(:prop_map) { { email: 'user.email' } }

      it { expect(result[:email]).to eq req_params['user.email'] }
    end

    context 'when request params contains password' do
      let(:req_params) { { 'password' => 'secret' } }
      let(:prop_map) { { password: 'password' } }

      it { expect(result[:password]).to eq true }
    end
  end
end
