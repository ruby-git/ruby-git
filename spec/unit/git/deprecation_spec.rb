# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Deprecation do
  describe '#deprecation_horizon' do
    it 'is the ADR-0007 wording "in a future major release"' do
      expect(described_class.deprecation_horizon).to eq('in a future major release')
    end
  end
end
