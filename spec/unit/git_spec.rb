# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.configure_deprecation_behavior' do
    subject { described_class.send(:configure_deprecation_behavior, deprecation, behavior) }

    let(:deprecation) { instance_double(ActiveSupport::Deprecation) }

    context 'when behavior is nil' do
      let(:behavior) { nil }

      it 'leaves the deprecation instance unchanged' do
        expect(deprecation).not_to receive(:behavior=)
        subject
      end
    end

    context 'when behavior is a valid name' do
      let(:behavior) { 'silence' }

      it 'sets the deprecation behavior to the corresponding symbol' do
        expect(deprecation).to receive(:behavior=).with(:silence)
        subject
      end
    end

    context 'when behavior has surrounding whitespace' do
      let(:behavior) { "  silence\n" }

      it 'strips the whitespace before applying the behavior' do
        expect(deprecation).to receive(:behavior=).with(:silence)
        subject
      end
    end

    context 'when behavior is invalid' do
      let(:behavior) { 'silent' }

      it 'raises an ArgumentError listing the allowed behaviors' do
        allowed = ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.keys.join(', ')

        expect { subject }.to raise_error(
          ArgumentError,
          %(Invalid GIT_DEPRECATION_BEHAVIOR="silent"; expected one of: #{allowed})
        )
      end
    end
  end
end
