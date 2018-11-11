# frozen_string_literal: true

describe Castle::Middleware::Tracking do
  let(:app) { double }
  let(:env) { {} }
  let(:response) { [200, {}, ''] }

  before do
    # Fake Rack Response
    module Rack
      class Request
        attr_accessor :env
        def initialize(env)
          @env = env
        end

        def cookies
          {}
        end

        def ip
          '127.0.0.1'
        end

        def params
          {}
        end
      end
    end

    allow(app).to receive(:call).and_return(response)
  end

  describe '#call' do
    subject(:call) { service.call(env) }

    let(:service) {  described_class.new(app) }
    let(:transport) { spy }
    let(:event_mapping) { spy }

    before do
      allow(::Castle::Middleware.instance.configuration.services).to receive(:transport).and_return(transport)
      allow(::Castle::Middleware::EventMapper).to receive(:build).and_return(event_mapping)
      allow(event_mapping).to receive(:find_by_rack_request).and_return(mapping)
      allow(service).to receive(:collect_event_properties).and_return({})
    end

    context 'when a mapping exists' do
      let(:mapping) { spy }

      before do
        allow(mapping).to receive(:properties).and_return({})
        allow(mapping).to receive(:event).and_return('$login.succeeded')
        call
      end

      it { expect(transport).to have_received(:call).once }
    end

    context 'when a mapping does not exists' do
      let(:mapping) { nil }

      before { call }

      it { expect(transport).not_to have_received(:call) }
    end
  end

  describe '::collect_event_properties' do
    subject(:result) { described_class.new(app).collect_event_properties(req_params, prop_map) }
    subject { result }

    let(:req_params) { { 'user.email' => 'testing', 'user.name' => 'John Doe' } }

    context 'when no properties defined in map' do
      let(:prop_map) { {} }

      it { is_expected.to be_empty }
    end

    context 'when properties contains key that matches request params' do
      let(:prop_map) { { email: 'user.email' } }

      it { expect(result[:email]).to eq req_params['user.email'] }
    end

    context 'when request params contains password' do
      let(:req_params) { { 'password' => 'secret' } }
      let(:prop_map) { { password: 'password' } }

      it { expect(result[:password]).to eq true }
    end
  end
end
