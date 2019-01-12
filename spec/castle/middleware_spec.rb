# frozen_string_literal: true

describe Castle::Middleware do
  describe '::configuration' do
    subject(:config) { described_class.instance.configuration }

    it { expect(config.api_secret).to be_eql('secret') }

    it { expect(Castle.config.port).to be_eql(3000) }
  end

  describe '::configure' do
    let(:configuration) { described_class.instance.configuration }

    context 'without block' do
      it { expect { described_class.configure }.to raise_error(ArgumentError) }
    end

    context 'with empty block' do
      it { expect { described_class.configure { |c| } }.to raise_error(Castle::Middleware::ConfigError) }
    end
  end

  describe '::call_error_handler' do
    context 'when error handler is defined' do
      let(:error_handler) { spy }
      let(:exception) { Exception.new }

      before { described_class.instance.configuration.options.services.error_handler = error_handler }

      context 'with a Proc' do
        before do
          described_class.instance.call_error_handler(exception)
        end

        it { expect(error_handler).to have_received(:call).with(exception).once }
      end
    end
  end

  describe '::track' do
    let(:api) { spy }

    before { allow(::Castle::Client).to receive(:new).and_return(api) }

    context 'when request raises exception' do
      before do
        allow(api).to receive(:track).and_raise(::Castle::Error)
        allow(described_class.instance).to receive(:call_error_handler)

        described_class.instance.track({}, {})
      end

      it { expect(described_class.instance).to have_received(:call_error_handler).once }
    end

    context 'when request does not raise an exception' do
      before do
        allow(described_class.instance).to receive(:call_error_handler)
        described_class.instance.track({}, {})
      end

      it { expect(described_class.instance).not_to have_received(:call_error_handler) }
    end
  end
end
