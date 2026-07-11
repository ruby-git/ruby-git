# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Deprecation do
  describe '.deprecation_horizon' do
    it 'is 6.0.0' do
      expect(described_class.deprecation_horizon).to eq('6.0.0')
    end
  end

  describe 'GIT_DEPRECATION_BEHAVIOR' do
    around do |example|
      original_verbose = $VERBOSE
      original_behavior = ENV.fetch('GIT_DEPRECATION_BEHAVIOR', nil)
      $VERBOSE = nil
      ENV['GIT_DEPRECATION_BEHAVIOR'] = behavior
      example.run
    ensure
      $VERBOSE = original_verbose
      if original_behavior.nil?
        ENV.delete('GIT_DEPRECATION_BEHAVIOR')
      else
        ENV['GIT_DEPRECATION_BEHAVIOR'] = original_behavior
      end
    end

    before { hide_const('Git::Deprecation') }

    let(:project_root) { File.expand_path('../../..', __dir__) }
    let(:allowed_behaviors) { ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.keys.map(&:to_s) }
    let(:deprecation_path) { File.join(project_root, 'lib/git.rb') }

    context 'when set to silence' do
      let(:behavior) { 'silence' }

      it 'silences deprecation warnings' do
        load deprecation_path

        expect { Git::Deprecation.warn('deprecated message') }.not_to output(
          /DEPRECATION WARNING: deprecated message/
        ).to_stderr
      end
    end

    context 'when set to an invalid behavior' do
      let(:behavior) { 'silent' }

      it 'raises a descriptive error' do
        expect { load deprecation_path }.to raise_error(
          ArgumentError,
          /Invalid GIT_DEPRECATION_BEHAVIOR="silent"; expected one of: #{Regexp.escape(allowed_behaviors.join(', '))}/
        )
      end
    end
  end
end
