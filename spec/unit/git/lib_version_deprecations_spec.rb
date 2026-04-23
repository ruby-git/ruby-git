# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Lib do
  subject(:lib) { described_class.new(nil, nil) }

  before do
    allow(Git::Deprecation).to receive(:warn)
  end

  describe '#current_command_version' do
    before do
      allow(lib).to receive(:git_version).and_return(Git::Version.new(2, 42, 0))
    end

    it 'emits a deprecation warning' do
      lib.current_command_version

      expect(Git::Deprecation).to have_received(:warn).with(
        'Git::Lib#current_command_version is deprecated and will be removed in 6.0. ' \
        'Use Git.git_version instead, which returns a Git::Version (not an Array). ' \
        'For the legacy array shape, call: Git.git_version.to_a'
      ).once
    end

    it 'emits exactly one deprecation warning per call' do
      lib.current_command_version

      expect(Git::Deprecation).to have_received(:warn).exactly(1).time
    end

    it 'still returns the version as an Array of integers' do
      result = lib.current_command_version

      expect(result).to eq([2, 42, 0])
    end
  end

  describe '#compare_version_to' do
    before do
      allow(lib).to receive(:git_version).and_return(Git::Version.new(2, 42, 0))
    end

    it 'emits a deprecation warning' do
      lib.compare_version_to(2, 41, 0)

      expect(Git::Deprecation).to have_received(:warn).with(
        'Git::Lib#compare_version_to is deprecated and will be removed in 6.0. ' \
        'Use Git.git_version with Git::Version comparison operators instead, ' \
        'e.g. Git.git_version <=> Git::Version.new(2, 41, 0)'
      ).once
    end

    it 'emits exactly one deprecation warning per call' do
      lib.compare_version_to(2, 41, 0)

      expect(Git::Deprecation).to have_received(:warn).exactly(1).time
    end

    it 'still returns the comparison result as an Integer' do
      expect(lib.compare_version_to(2, 41, 0)).to eq(1)
      expect(lib.compare_version_to(2, 42, 0)).to eq(0)
      expect(lib.compare_version_to(2, 43, 0)).to eq(-1)
    end
  end

  describe '#required_command_version' do
    it 'emits a deprecation warning' do
      lib.required_command_version

      expect(Git::Deprecation).to have_received(:warn).with(
        'Git::Lib#required_command_version is deprecated and will be removed in 6.0. ' \
        'Use the Git::MINIMUM_GIT_VERSION constant instead, which returns a Git::Version ' \
        '(not an Array). For the legacy array shape, call: Git::MINIMUM_GIT_VERSION.to_a.first(2)'
      ).once
    end

    it 'emits exactly one deprecation warning per call' do
      lib.required_command_version

      expect(Git::Deprecation).to have_received(:warn).exactly(1).time
    end

    it 'still returns [2, 28]' do
      expect(lib.required_command_version).to eq([2, 28])
    end
  end

  describe '#meets_required_version?' do
    before do
      allow(lib).to receive(:git_version).and_return(Git::Version.new(2, 42, 0))
    end

    it 'emits a deprecation warning' do
      lib.meets_required_version?

      expect(Git::Deprecation).to have_received(:warn).with(
        'Git::Lib#meets_required_version? is deprecated and will be removed in 6.0. ' \
        'For a boolean check, use: Git.git_version >= Git::MINIMUM_GIT_VERSION. ' \
        'For enforcement, no action is needed: Git::Commands::Base#call automatically ' \
        'invokes validate_version!, which raises Git::VersionError on failure.'
      ).once
    end

    it 'emits exactly one deprecation warning per call' do
      lib.meets_required_version?

      expect(Git::Deprecation).to have_received(:warn).exactly(1).time
    end

    it 'returns true when version meets requirements' do
      expect(lib.meets_required_version?).to be(true)
    end
  end
end
