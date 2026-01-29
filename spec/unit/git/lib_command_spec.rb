# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Lib do
  let(:base) { instance_double(Git::Base) }
  let(:logger) { Logger.new(nil) }
  let(:command_line) { instance_double(Git::CommandLine) }

  subject(:lib) { described_class.new(base, logger) }

  before do
    allow(lib).to receive(:command_line).and_return(command_line)
  end

  describe '#command' do
    let(:successful_result) do
      instance_double(
        Git::CommandLineResult,
        stdout: 'git version 2.40.0',
        stderr: '',
        status: instance_double(Process::Status, success?: true)
      )
    end

    let(:failed_result) do
      instance_double(
        Git::CommandLineResult,
        git_cmd: %w[git rev-parse nonexistent],
        stdout: '',
        stderr: 'fatal: not a git repository',
        status: instance_double(Process::Status, success?: false)
      )
    end

    context 'when command succeeds' do
      it 'returns a CommandLineResult' do
        allow(command_line).to receive(:run).and_return(successful_result)

        result = lib.command('version')

        expect(result).to be(successful_result)
      end
    end

    context 'when command fails with non-zero exit (default behavior)' do
      it 'raises Git::FailedError' do
        allow(command_line).to receive(:run).and_raise(Git::FailedError.new(failed_result))

        expect do
          lib.command('rev-parse', 'nonexistent')
        end.to raise_error(Git::FailedError)
      end
    end

    context 'when command fails with raise_on_failure: false' do
      it 'returns CommandLineResult without raising' do
        allow(command_line).to receive(:run).and_return(failed_result)

        result = lib.command('rev-parse', 'nonexistent', raise_on_failure: false)

        expect(result).to be(failed_result)
        expect(result.status.success?).to be false
      end
    end

    context 'with env: option' do
      it 'merges env into the command_line call' do
        allow(command_line).to receive(:run).and_return(successful_result)

        lib.command('rev-parse', '--git-dir', env: { 'GIT_DIR' => '/custom/path' })

        expect(command_line).to have_received(:run).with(
          'rev-parse', '--git-dir',
          hash_including(env: { 'GIT_DIR' => '/custom/path' })
        )
      end
    end
  end
end
