# frozen_string_literal: true

describe Castle::Middleware::Sensor do
  let(:app) { double }
  let(:env) { {} }
  let(:response) { [status, headers, body] }
  let(:body) { ['<html><head></head></html>'] }
  let(:headers) { { 'Content-Type' => 'text/html' } }
  let(:user) { spy }

  before do
    # Fake Rack Response
    module Rack
      class Response
        def initialize(b, s, h)
          @s = s
          @h = h
          @b = b
        end

        def finish
          [@s, @h, @b]
        end
      end
    end

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

        def xhr?
          false
        end
      end
    end

    allow(::Castle::Middleware.instance.configuration.services).to receive(:provide_user) { lambda { |_r, _s| user } }
    allow(::Castle::Middleware.instance.configuration).to receive(:api_secret).and_return('secret')
    allow(app).to receive(:call).and_return(response)
  end

  matcher :inject_the_script do
    match_unless_raises do |subscriber|
      expect(subscriber[2]).to include ::Castle::Middleware::BodyModify::CJS_PATH
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

    context 'when response is nil' do
      let(:response) { nil }

      it { is_expected.to be(nil) }
    end

    context 'with HTML body' do
      let(:status) { 200 }
      let(:user) { nil }

      it { is_expected.to inject_the_script }
    end

    context 'with non 200 code' do
      let(:status) { 400 }
      let(:body) { [''] }
      let(:user) { nil }

      it { is_expected.not_to inject_the_script }
    end

    context 'when user_id is set' do
      let(:status) { 200 }

      before do
        allow(user).to receive(:id).with('1')
      end

      it { is_expected.to inject_the_identify_tag }
      it { is_expected.to inject_the_secure_tag }
    end
  end
end
