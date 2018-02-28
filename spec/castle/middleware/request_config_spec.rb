# frozen_string_literal: true

describe Castle::Middleware::RequestConfig do
  subject(:instance) { described_class.new }

  describe '#identify' do
    let(:user_id) { 1 }
    let(:traits) { { name: 'John Doe' } }

    before { instance.identify(user_id, traits) }

    it { expect(instance.user_id).to eq user_id }
    it { expect(instance.traits).to eq traits }
  end

  describe '#properties' do
    let(:props) { { details: true } }

    before { instance.properties(props) }

    it { expect(instance.props).to eq props }
  end
end
