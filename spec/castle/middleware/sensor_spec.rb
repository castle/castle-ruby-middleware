# frozen_string_literal: true

require 'spec_helper'

describe Castle::Middleware::Sensor do
  let(:app) { double }
  let(:env) { {} }
  let(:response) { [status, headers, body] }
  let(:request_config) { ::Castle::Middleware::RequestConfig.new }
  let(:body) { ['<html><head></head></html>'] }
  let(:headers) { { 'Content-Type' => 'text/html' } }

  before do
    # Fake Rack Response
    module Rack
      class Response
        def initialize(b, s, h)
          @s, @h, @b = [s, h, b]
        end

        def finish
          [@s, @h, @b]
        end
      end
    end

    allow(Castle::Middleware.configuration).to receive(:api_secret) { 'secret' }
    allow(env).to receive(:[]).with(described_class::JS_IS_INJECTED_KEY) { false }
    allow(env).to receive(:[]).with('castle') { request_config }
    allow(app).to receive(:call).and_return(response)
  end

  matcher :inject_the_script do
    match_unless_raises do |subscriber|
      expect(subscriber[2]).to include described_class::SNIPPET
    end
  end

  matcher :inject_the_identify_tag do
    match_unless_raises do |subscriber|
      expect(subscriber[2]).to include "_castle('identify',"
    end
  end

  matcher :inject_the_secure_tag do
    match_unless_raises do |subscriber|
      expect(subscriber[2]).to include "_castle('secure',"
    end
  end

  describe '#call' do
    subject { described_class.new(app).call(env) }

    context 'with HTML body' do
      let(:status) { 200 }

      it { is_expected.to inject_the_script }
    end

    context 'with non 200 code' do
      let(:status) { 400 }
      let(:body) { [''] }

      it { is_expected.to_not inject_the_script }
    end

    context 'when user_id is set' do
      let(:status) { 200 }

      before { request_config.identify(1, nil) }

      it { is_expected.to inject_the_identify_tag }
      it { is_expected.to inject_the_secure_tag }
    end
  end
end
