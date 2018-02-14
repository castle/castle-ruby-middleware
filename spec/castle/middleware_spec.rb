# frozen_string_literal: true

describe Castle::Middleware do
  describe '::configuration' do
    subject(:config) { described_class.configuration }

    before do
      described_class.configure do |config|
        config.api_secret = 'secret'
      end
    end

    it { expect(config.api_secret).to be_eql('secret') }
  end

  context '.event_mapping' do
    subject { described_class.event_mapping.events }
    context 'when configured' do
      before do
        described_class.configuration.events = {
          '$login.failed' => { status: 400, path: '/', method: 'POST' }
        }
      end

      it { is_expected.to include '$login.failed' }
    end

    context 'when not configured' do
      it { is_expected.to be_empty }
    end
  end

  describe '::configure' do
    let(:configuration) { described_class.configuration }

    context 'without block' do
      it { expect { described_class.configure }.to raise_error(ArgumentError) }
    end

    context 'with block' do
      it { expect { |b| described_class.configure(&b) }.to yield_with_args(configuration) }
    end
  end

  describe '::call_error_handler' do
    context 'when error handler is defined' do
      let(:error_handler) { spy }
      let(:exception) { Exception.new }

      before { described_class.configuration.error_handler = error_handler }

      context 'with a Proc' do
        before do
          allow(error_handler).to receive(:is_a?).and_return(Proc)
          described_class.call_error_handler(exception)
        end

        it { expect(error_handler).to have_received(:call).with(exception).once }
      end
    end
  end

  describe '::track' do
    let(:api) { spy }

    before { allow(::Castle::API).to receive(:new).and_return(api) }

    context 'when request raises exception' do
      before do
        allow(api).to receive(:request).and_raise(::Castle::Error)
        allow(described_class).to receive(:call_error_handler)

        described_class.track({}, {})
      end

      it { expect(described_class).to have_received(:call_error_handler).once }
    end

    context 'when request does not raise an exception' do
      before do
        allow(described_class).to receive(:call_error_handler)
        described_class.track({}, {})
      end

      it { expect(described_class).not_to have_received(:call_error_handler) }
    end
  end
end
