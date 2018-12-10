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
    let(:properties_provide) { {} }
    let(:user) { spy }

    before do
      allow(::Castle::Middleware.instance.configuration.services).to receive(:transport).and_return(transport)
      allow(::Castle::Middleware.instance.configuration.services).to receive(:provide_user).and_return(user)
      allow(::Castle::Middleware::EventMapper).to receive(:build).and_return(event_mapping)
      allow(event_mapping).to receive(:find_by_rack_request).and_return(mapping)
      allow(::Castle::Middleware::PropertiesProvide).to receive(:call).and_return(properties_provide)
    end

    context 'when a mapping exists' do
      let(:mapping) { spy }

      before do
        allow(mapping).to receive(:properties).and_return({})
        allow(mapping).to receive(:event).and_return('$logout.succeeded')
        allow(user).to receive(:created_at).and_return(Time.now)
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
end
