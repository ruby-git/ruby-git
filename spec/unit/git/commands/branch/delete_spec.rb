# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/delete'

RSpec.describe Git::Commands::Branch::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with single branch name' do
      it 'runs branch --delete with the branch name' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'feature-branch', raise_on_failure: false)
          .and_return(command_result("Deleted branch feature-branch (was abc1234).\n"))

        result = command.call('feature-branch')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq("Deleted branch feature-branch (was abc1234).\n")
      end
    end

    context 'with multiple branch names' do
      it 'passes all branch names as operands' do
        stdout = "Deleted branch branch1 (was abc1234).\n" \
                 "Deleted branch branch2 (was abc1234).\n" \
                 "Deleted branch branch3 (was abc1234).\n"
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'branch1', 'branch2', 'branch3', raise_on_failure: false)
          .and_return(command_result(stdout))

        result = command.call('branch1', 'branch2', 'branch3')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--force', 'feature-branch', raise_on_failure: false)
          .and_return(command_result("Deleted branch feature-branch (was abc1234).\n"))

        result = command.call('feature-branch', force: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :f alias' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--force', 'feature-branch', raise_on_failure: false)
          .and_return(command_result("Deleted branch feature-branch (was abc1234).\n"))

        result = command.call('feature-branch', f: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :remotes option' do
      it 'adds --remotes flag' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(command_result("Deleted remote-tracking branch origin/feature (was abc1234).\n"))

        result = command.call('origin/feature', remotes: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :r alias' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(command_result("Deleted remote-tracking branch origin/feature (was abc1234).\n"))

        result = command.call('origin/feature', r: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--force', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(command_result("Deleted remote-tracking branch origin/feature (was abc1234).\n"))

        result = command.call('origin/feature', force: true, remotes: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 0 (all deleted)' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'feature', raise_on_failure: false)
          .and_return(command_result("Deleted branch feature (was abc1234).\n", exitstatus: 0))

        result = command.call('feature')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns result for exit code 1 (partial failure)' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'feature', 'nonexistent', raise_on_failure: false)
          .and_return(
            command_result(
              "Deleted branch feature (was abc1234).\n",
              stderr: "error: branch 'nonexistent' not found.\n",
              exitstatus: 1
            )
          )

        result = command.call('feature', 'nonexistent')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError for exit code > 1' do
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'feature', raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: error', exitstatus: 128))

        expect { command.call('feature') }.to raise_error(Git::FailedError)
      end
    end
  end
end
