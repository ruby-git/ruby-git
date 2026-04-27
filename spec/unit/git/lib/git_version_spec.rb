# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Lib do
  describe '#git_version' do
    let(:lib) { described_class.new(nil) }
    let(:version_command) { instance_double(Git::Commands::Version) }
    let(:version_output) { 'git version 2.42.1' }
    let(:parsed_version) { Git::Version.new(2, 42, 1) }

    before do
      # Clear the class-level cache so each test starts fresh
      described_class.clear_git_version_cache

      allow(Git::Commands::Version).to receive(:new).and_return(version_command)
    end

    it 'returns a Git::Version parsed from `git version` output' do
      allow(version_command).to receive(:call).and_return(command_result(version_output))
      expect(Git::Version).to receive(:parse).with(version_output).and_return(parsed_version)

      expect(lib.git_version).to eq(parsed_version)
    end

    context 'with unparseable output' do
      it 'raises Git::UnexpectedResultError' do
        allow(version_command).to receive(:call).and_return(command_result('not a version'))
        allow(Git::Version).to receive(:parse).and_raise(Git::UnexpectedResultError, 'Invalid version')

        expect { lib.git_version }.to raise_error(Git::UnexpectedResultError, 'Invalid version')
      end
    end

    context 'memoization' do
      it 'caches the result' do
        allow(version_command).to receive(:call).and_return(command_result(version_output))

        first_call = lib.git_version
        second_call = lib.git_version

        expect(first_call).to equal(second_call)
        expect(version_command).to have_received(:call).once
      end

      it 'isolates the class-level cache by binary_path' do
        original_binary_path = Git::Base.config.binary_path
        allow(version_command).to receive(:call).and_return(
          command_result('git version 2.42.1'),
          command_result('git version 2.42.2')
        )

        begin
          Git::Base.config.binary_path = '/usr/bin/git-first'
          first_path_version = described_class.new(nil).git_version

          Git::Base.config.binary_path = '/usr/bin/git-second'
          second_path_version = described_class.new(nil).git_version

          Git::Base.config.binary_path = '/usr/bin/git-first'
          cached_first_path_version = described_class.new(nil).git_version

          expect(first_path_version).to eq(Git::Version.new(2, 42, 1))
          expect(second_path_version).to eq(Git::Version.new(2, 42, 2))
          expect(cached_first_path_version).to equal(first_path_version)
          expect(version_command).to have_received(:call).twice
        ensure
          Git::Base.config.binary_path = original_binary_path
          described_class.clear_git_version_cache
        end
      end
    end
  end
end
