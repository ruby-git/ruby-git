# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'

RSpec.describe Git::Deprecation do
  describe '.deprecation_horizon' do
    it 'is 6.0.0' do
      expect(described_class.deprecation_horizon).to eq('6.0.0')
    end
  end

  describe 'GIT_DEPRECATION_BEHAVIOR' do
    around do |example|
      original_verbose = $VERBOSE
      $VERBOSE = nil
      example.run
    ensure
      $VERBOSE = original_verbose
    end

    subject(:load_deprecation) do
      Open3.capture3(
        env,
        RbConfig.ruby,
        '-Ilib',
        '-e',
        script,
        chdir: project_root
      )
    end

    let(:project_root) { File.expand_path('../../..', __dir__) }
    let(:env) { { 'GIT_DEPRECATION_BEHAVIOR' => behavior } }
    let(:allowed_behaviors) { ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.keys.map(&:to_s) }
    let(:deprecation_path) { File.join(project_root, 'lib/git/deprecation.rb') }
    let(:script) do
      <<~RUBY
        require 'git/deprecation'
        Git::Deprecation.warn('deprecated message')
      RUBY
    end

    context 'when set to silence' do
      let(:behavior) { 'silence' }

      it 'silences deprecation warnings' do
        _stdout, stderr, status = load_deprecation

        expect(status).to be_success
        expect(stderr).not_to include('DEPRECATION WARNING: deprecated message')
      end

      it 'sets the behavior when loaded in the current process' do
        original_behavior = ENV.fetch('GIT_DEPRECATION_BEHAVIOR', nil)

        ENV['GIT_DEPRECATION_BEHAVIOR'] = behavior
        hide_const('Git::Deprecation')
        load deprecation_path

        expect { Git::Deprecation.warn('deprecated message') }.not_to output(
          /DEPRECATION WARNING: deprecated message/
        ).to_stderr
      ensure
        if original_behavior.nil?
          ENV.delete('GIT_DEPRECATION_BEHAVIOR')
        else
          ENV['GIT_DEPRECATION_BEHAVIOR'] = original_behavior
        end
      end
    end

    context 'when set to an invalid behavior' do
      let(:behavior) { 'silent' }
      let(:script) { "require 'git/deprecation'" }

      it 'raises a descriptive error' do
        _stdout, stderr, status = load_deprecation

        expect(status).not_to be_success
        expect(stderr).to include('Invalid GIT_DEPRECATION_BEHAVIOR="silent"')
        expect(stderr).to include("expected one of: #{allowed_behaviors.join(', ')}")
      end

      it 'raises a descriptive error when loaded in the current process' do
        original_behavior = ENV.fetch('GIT_DEPRECATION_BEHAVIOR', nil)

        ENV['GIT_DEPRECATION_BEHAVIOR'] = behavior
        hide_const('Git::Deprecation')

        expect { load deprecation_path }.to raise_error(
          ArgumentError,
          /Invalid GIT_DEPRECATION_BEHAVIOR="silent"; expected one of: #{Regexp.escape(allowed_behaviors.join(', '))}/
        )
      ensure
        if original_behavior.nil?
          ENV.delete('GIT_DEPRECATION_BEHAVIOR')
        else
          ENV['GIT_DEPRECATION_BEHAVIOR'] = original_behavior
        end
      end
    end
  end
end
