# frozen_string_literal: true

describe Castle::Middleware::Transport::Sync do
  describe '#call' do
    let(:params) { spy }
    let(:context) { spy }

    before do
      allow(::Castle::Middleware).to receive(:track)
      described_class.call(params, context)
    end

    it { expect(::Castle::Middleware).to have_received(:track).with(params, context) }
  end
end
