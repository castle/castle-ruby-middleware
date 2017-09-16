# frozen_string_literal: true

require 'spec_helper'

describe Castle::Middleware::ParamsFlatter do
  describe '::call' do
    subject { described_class.(params) }

    let(:formatted) { { 'user.address.city' => 'Svenborgia' } }

    context 'when params is nested' do
      let(:params) { { user: { address: { city: 'Svenborgia' } } } }

      it { is_expected.to be_eql(formatted) }
    end

    context 'when params is not nested' do
      let(:params) { { 'user.address.city' => 'Svenborgia' } }

      it { is_expected.to be_eql(formatted) }
    end
  end
end
