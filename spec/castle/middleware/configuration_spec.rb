# frozen_string_literal: true

describe Castle::Middleware::Configuration do
  subject(:instance) { described_class.new(Castle::Middleware::Configuration::Options.new) }

  describe '#events.size' do
    subject { instance.events.size }

    before do
      allow(instance.options).to receive(:file_path) do
        File.expand_path(path, File.dirname(__FILE__))
      end

      instance.load_config_file
    end

    context 'when existing config file is loaded' do
      let(:path) { './castle_config.yml' }

      it { is_expected.to be_eql 3 }
    end

    context 'when non-existing config is loaded' do
      let(:path) { './non-existing.yml' }

      it { is_expected.to be_eql 0 }
    end
  end

  describe '#events.path' do
    subject { instance.events.values[1]['path'] }

    before do
      allow(instance.options).to receive(:file_path) do
        File.expand_path(path, File.dirname(__FILE__))
      end

      instance.load_config_file
    end

    context 'when path config contains regex' do
      let(:path) { './castle_config.yml' }

      it { is_expected.to be_an_instance_of(::Regexp) }
    end
  end
end
