# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Deprecation do
  describe '#deprecation_horizon' do
    it 'is 6.0.0' do
      expect(described_class.deprecation_horizon).to eq('6.0.0')
    end
  end
end
