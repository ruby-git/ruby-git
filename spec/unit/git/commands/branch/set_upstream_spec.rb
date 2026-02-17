# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/set_upstream'

RSpec.describe Git::Commands::Branch::SetUpstream do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only set_upstream_to (set upstream for current branch)' do
      it 'runs branch --set-upstream-to=<upstream>' do
        expect_command('branch', '--set-upstream-to=origin/main')
          .and_return(command_result("branch 'main' set up to track 'origin/main'.\n"))

        result = command.call(set_upstream_to: 'origin/main')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq("branch 'main' set up to track 'origin/main'.\n")
      end
    end

    context 'with -u short alias' do
      it 'runs branch --set-upstream-to=<upstream>' do
        expect_command('branch', '--set-upstream-to=origin/main')
          .and_return(command_result(''))

        result = command.call(u: 'origin/main')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with set_upstream_to and branch_name' do
      it 'runs branch --set-upstream-to=<upstream> <branch>' do
        expect_command('branch', '--set-upstream-to=origin/main', 'feature')
          .and_return(command_result(''))

        result = command.call('feature', set_upstream_to: 'origin/main')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with remote-tracking branch as upstream' do
      it 'accepts various remote-tracking branch formats' do
        expect_command('branch', '--set-upstream-to=upstream/develop')
          .and_return(command_result(''))

        result = command.call(set_upstream_to: 'upstream/develop')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when set_upstream_to is missing' do
        expect { command.call }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when set_upstream_to is missing even with branch_name' do
        expect { command.call('feature') }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError for unknown options' do
        expect do
          command.call(set_upstream_to: 'origin/main', unknown: true)
        end.to raise_error(ArgumentError, /unknown/)
      end
    end
  end
end
