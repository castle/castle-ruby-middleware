# frozen_string_literal: true

describe Castle::Middleware::EventMapper do
  let(:valid_config) do
    {
      '$login.failed' => {
        'method' => 'POST',
        'path' => '/sign_in',
        'status' => '302'
      }
    }
  end

  let(:broken_path) { "signup/DirMHlj0'))" }

  describe '::build' do
    subject(:builder) { described_class.build(config) }

    context 'with valid config' do
      let(:config) { valid_config }

      it { expect(builder).to be_an_instance_of(described_class) }
    end
  end

  describe '#add' do
    subject(:instance) { described_class.new }

    context 'with valid arguments' do
      let(:arguments) { ['$login.failed', { status: '404' }] }

      it { expect { instance.add(*arguments) }.to change(instance, :size).by 1 }
    end
  end

  describe '#find single config' do
    subject { described_class.build(valid_config).find(conditions).first }

    context 'with matching conditions' do
      let(:conditions) { { status: '302', path: '/sign_in', method: 'POST', authenticate: false } }

      it { is_expected.to be_an_instance_of(described_class::Mapping) }
    end

    context 'without matching conditions' do
      let(:conditions) { { status: '400', path: '/sign_in', method: 'POST', authenticate: false } }

      it { is_expected.to be_nil }
    end

    context 'when wrong non utf path is used' do
      let(:conditions) do
        { status: '302', path: broken_path, method: 'POST', authenticate: false }
      end

      it { is_expected.to be_nil }
    end

    context 'when query params included' do
      let(:query_param) { 'token=123' }

      before { valid_config['$login.failed']['query'] = /token=/ }

      context 'when query is used' do
        let(:conditions) do
          {
            query: 'z1=3&token=123&z=2', status: '302',
            path: '/sign_in', method: 'POST', authenticate: false
          }
        end

        it { is_expected.to be_an_instance_of(described_class::Mapping) }
      end
    end

    context 'when referer is used' do
      let(:referer) { '/test' }

      before { valid_config['$login.failed']['referer'] = referer }

      context 'when wrong non utf referer is used' do
        let(:conditions) do
          {
            status: '302', referer: broken_path,
            path: '/sign_in', method: 'POST', authenticate: false
          }
        end

        it { is_expected.to be_nil }
      end

      context 'when correct referer is used' do
        let(:conditions) do
          { status: '302', referer: referer, path: '/sign_in', method: 'POST', authenticate: false }
        end

        it { is_expected.to be_an_instance_of(described_class::Mapping) }
      end
    end
  end

  describe '#find with regex path in config' do
    subject { described_class.build(regex_config).find(conditions).first }

    let(:regex_config) do
      { '$login.failed' => { status: '400', path: %r{/users/\d+$}, method: 'POST' } }
    end

    context 'and with matching conditions' do
      let(:conditions) do
        { status: '400', path: '/users/1234', method: 'POST', authenticate: false }
      end

      it { is_expected.to be_an_instance_of(described_class::Mapping) }
    end

    context 'and without matching conditions' do
      let(:conditions) do
        { status: '400', path: '/users/1234/account', method: 'POST', authenticate: false }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#find with array config' do
    let(:valid_config) do
      {
        '$login.failed' => [
          {
            'method' => 'POST',
            'path' => '/sign_in',
            'status' => '302'
          },
          {
            'method' => 'POST',
            'path' => '/login',
            'status' => '400'
          }
        ]
      }
    end

    subject { described_class.build(valid_config).find(conditions).first }

    context 'when matching first item' do
      let(:conditions) { { status: '302', path: '/sign_in', method: 'POST', authenticate: false } }

      it { is_expected.to be_an_instance_of(described_class::Mapping) }
    end

    context 'when matching second item' do
      let(:conditions) { { status: '400', path: '/login', method: 'POST', authenticate: false } }

      it { is_expected.to be_an_instance_of(described_class::Mapping) }
    end

    context 'when no match' do
      let(:conditions) { { status: '400', path: '/logout', method: 'POST', authenticate: false } }

      it { is_expected.to be_nil }
    end
  end
end
