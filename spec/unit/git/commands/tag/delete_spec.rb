# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/delete'

RSpec.describe Git::Commands::Tag::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    let(:delete_output) { "Deleted tag 'v1.0.0' (was abc123)\n" }

    context 'with single tag name' do
      it 'deletes the tag' do
        expect_command('tag', '--delete', 'v1.0.0').and_return(command_result(delete_output))

        result = command.call('v1.0.0')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq(delete_output)
      end
    end

    context 'with multiple tag names' do
      let(:multi_delete_output) do
        "Deleted tag 'v1.0.0' (was abc123)\n" \
          "Deleted tag 'v2.0.0' (was def456)\n" \
          "Deleted tag 'v3.0.0' (was ghi789)\n"
      end

      it 'deletes all specified tags in one command' do
        expect_command('tag', '--delete', 'v1.0.0', 'v2.0.0', 'v3.0.0')
          .and_return(command_result(multi_delete_output))

        result = command.call('v1.0.0', 'v2.0.0', 'v3.0.0')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq(multi_delete_output)
      end
    end

    context 'with various tag name formats' do
      it 'handles semver tags' do
        expect_command('tag', '--delete', 'v1.2.3')
          .and_return(command_result("Deleted tag 'v1.2.3' (was abc)\n"))

        result = command.call('v1.2.3')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles tags with slashes' do
        expect_command('tag', '--delete', 'release/v1.0')
          .and_return(command_result("Deleted tag 'release/v1.0' (was abc)\n"))

        result = command.call('release/v1.0')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'handles tags with hyphens and underscores' do
        expect_command('tag', '--delete', 'my-tag_name')
          .and_return(command_result("Deleted tag 'my-tag_name' (was abc)\n"))

        result = command.call('my-tag_name')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 0 (all deleted)' do
        allow(execution_context).to receive(:command)
          .with('tag', '--delete', 'v1.0.0', raise_on_failure: false)
          .and_return(command_result(delete_output))

        result = command.call('v1.0.0')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns result for exit code 1 (partial failure)' do
        partial_result = command_result(
          "Deleted tag 'v1.0.0' (was abc123)\n",
          stderr: "error: tag 'nonexistent' not found.",
          exitstatus: 1
        )
        allow(execution_context).to receive(:command)
          .with('tag', '--delete', 'v1.0.0', 'nonexistent', raise_on_failure: false)
          .and_return(partial_result)

        result = command.call('v1.0.0', 'nonexistent')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError for exit code > 1 (fatal error)' do
        fatal_result = command_result(
          '',
          stderr: 'fatal: some unexpected error',
          exitstatus: 128
        )
        allow(execution_context).to receive(:command)
          .with('tag', '--delete', 'v1.0.0', raise_on_failure: false)
          .and_return(fatal_result)

        expect { command.call('v1.0.0') }.to raise_error(Git::FailedError)
      end
    end
  end
end
