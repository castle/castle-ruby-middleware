# frozen_string_literal: true

describe Castle::Middleware::Identification do
  let(:user) { spy }
  let(:traits) { { name: 'John Doe' } }

  describe '#id' do
    subject do
      described_class.id(user, ::Castle::Middleware.instance.configuration.identify)
    end

    context 'when user is defined' do
      before do
        allow(user).to receive(:uuid).and_return(1)
      end

      it { is_expected.to eq('1') }
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to eq(false) }
    end
  end

  describe '#traits' do
    subject do
      described_class.traits(user, ::Castle::Middleware.instance.configuration.user_traits)
    end

    context 'when user is defined' do
      let(:time) { Time.parse('2018-12-10 10:00:00 UTC').utc }

      before do
        allow(user).to receive(:email).and_return('email')
        allow(user).to receive(:created_at).and_return(time)
        allow(user).to receive(:full_name).and_return('full_name')
      end

      it { is_expected.to eq(email: 'email', name: 'full_name', registered_at: '2018-12-10T10:00:00Z') }
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to eq({}) }
    end
  end
end
