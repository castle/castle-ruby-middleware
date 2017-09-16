# frozen_string_literal: true

require 'spec_helper'

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
end
