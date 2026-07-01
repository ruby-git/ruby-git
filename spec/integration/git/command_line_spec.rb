# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'CommandLine::Capturing#run raise_on_failure integration' do
  include_context 'in an empty repository'

  let(:command_line) do
    Git::CommandLine::Capturing.new({}, 'git', [], Logger.new(nil))
  end

  describe 'raise_on_failure: false' do
    it 'returns CommandLineResult without raising on non-zero exit' do
      result = command_line.run('rev-parse', 'nonexistent-ref', chdir: repo_dir, raise_on_failure: false)

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.status.success?).to be false
      expect(result.stderr).to include('unknown revision')
    end
  end

  describe 'raise_on_failure: true (default)' do
    it 'raises FailedError on non-zero exit' do
      expect do
        command_line.run('rev-parse', 'nonexistent-ref', chdir: repo_dir)
      end.to raise_error(Git::FailedError)
    end
  end
end

RSpec.describe Git::CommandLine::Capturing, :integration do
  let(:command_line_test_fixture) do
    File.expand_path('../../support/fixtures/command_line_test', __dir__)
  end
  let(:described_instance) do
    described_class.new({}, 'ruby', [command_line_test_fixture], Logger.new(nil))
  end

  describe '#run' do
    context 'when the command exceeds the timeout' do
      it 'raises Git::TimeoutError naming the timed-out command' do
        expect { described_instance.run('--duration=5', timeout: 0.01) }
          .to raise_error(Git::TimeoutError, /timed out after/)
      end
    end

    context 'when the command exits due to an uncaught signal' do
      before do
        skip 'Ruby on Windows does not support signals' if Gem.win_platform?
        # TruffleRuby < 25.0.0 reports signal-killed processes as "exit nil" rather
        # than "SIGKILL (signal 9)", so the message pattern and termsig check cannot
        # be relied upon.
        skip 'TruffleRuby does not correctly report signal termination status' if RUBY_ENGINE == 'truffleruby'
      end

      it 'raises Git::SignaledError with the signal number in the result' do
        expect { described_instance.run('--signal=9', '--stderr=O2') }
          .to raise_error(Git::SignaledError, /signal 9/) do |error|
            expect(error.result.status.termsig).to eq(9)
          end
      end
    end

    context 'when merge: true' do
      it 'includes both stdout and stderr in result.stdout' do
        result = described_instance.run('--stdout=stdout output', '--stderr=stderr output', merge: true)
        expect(result.stdout).to include('stdout output')
        expect(result.stdout).to include('stderr output')
      end
    end

    context 'when out: is a writable IO object' do
      it 'writes stdout to that IO object' do
        Tempfile.create do |f|
          described_instance.run('--stdout=stdout output', out: f)
          f.flush
          f.rewind
          expect(f.read.chomp).to eq('stdout output')
        end
      end
    end

    context 'when merge: true and out: is a writable IO object' do
      it 'writes both stdout and stderr to the same IO object' do
        Tempfile.create do |f|
          described_instance.run('--stdout=STARTING PROCESS', '--stderr=ERROR: fatal error', out: f, merge: true)
          f.flush
          f.rewind
          output = f.read
          expect(output).to include('STARTING PROCESS')
          expect(output).to include('ERROR: fatal error')
        end
      end
    end
  end
end
