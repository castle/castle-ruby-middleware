# frozen_string_literal: true

describe Castle::Middleware::Identification do
  let(:user) { spy }
  let(:traits) { { name: 'John Doe' } }

  describe '#id' do
    subject do
      described_class.id(user, ::Castle::Middleware.instance.configuration.identify)
    end

    before do
      allow(user).to receive(:uuid).and_return(1)
    end

    it { is_expected.to eq('1') }
  end

  describe '#traits' do
    subject do
      described_class.traits(user, ::Castle::Middleware.instance.configuration.identify)
    end

    before do
      allow(user).to receive(:email).and_return('email')
      allow(user).to receive(:full_name).and_return('full_name')
    end

    it { is_expected.to eq(email: 'email', name: 'full_name') }
  end
end
