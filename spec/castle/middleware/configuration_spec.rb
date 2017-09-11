# frozen_string_literal: true

require 'spec_helper'

describe Castle::Middleware::Configuration do
  describe '#reset!' do
    subject(:instance) { described_class.new }

    before { instance.api_secret = 'secret' }

    it { expect { instance.reset! }.to change(instance, :api_secret).to nil }
  end
end
