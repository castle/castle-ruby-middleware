# frozen_string_literal: true

require 'spec_helper'

describe Castle::Middleware::EventMapper do
  let(:valid_config) do
    {
      '$login.failed' => {
        'method' => 'POST',
        'path' => '/sign_in',
        'status' => 302
      }
    }
  end

  describe '::build' do
    subject(:builder) { described_class.build(config) }

    context 'with valid config' do
      let(:config) { valid_config }

      it { expect(builder).to be_an_instance_of(described_class) }
    end

    context 'with invalid config' do
      let(:config) { [] }

      it { expect { builder }.to raise_error(ArgumentError) }
    end
  end

  describe '#add' do
    subject(:instance) { described_class.new }

    context 'with valid arguments' do
      let(:arguments) { ['$login.failed', { status: 404 }] }

      it { expect { instance.add(*arguments) }.to change(instance, :size).by 1 }
    end

    context 'with invalid arguments' do
      let(:arguments) { ['$login.failed', nil] }

      it { expect { instance.add(*arguments) }.to raise_error(ArgumentError) }
    end
  end

  describe '#find' do
    subject { described_class.build(valid_config).find(conditions) }

    context 'with matching conditions' do
      let(:conditions) { { status: 302, path: '/sign_in', method: 'POST' } }

      it { is_expected.to be_an_instance_of(described_class::Object) }
    end

    context 'without matching conditions' do
      let(:conditions) { { status: 400, path: '/sign_in', method: 'POST' } }

      it { is_expected.to be_nil }
    end

    context 'with regex path in config' do
      let(:valid_config) do
        { '$login.failed' => { status: 400, path: /\/users\/\d+$/, method: 'POST' } }
      end

      context 'and with matching conditions' do
        let(:conditions) { { status: 400, path: '/users/1234', method: 'POST' } }

        it { is_expected.to be_an_instance_of(described_class::Object) }
      end

      context 'and without matching conditions' do
        let(:conditions) { { status: 400, path: '/users/1234/account', method: 'POST' } }

        it { is_expected.to be_nil }
      end
    end
  end
end
