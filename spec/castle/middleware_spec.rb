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
