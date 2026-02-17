# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show_numstat'

RSpec.describe Git::Commands::Stash::ShowNumstat do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  let(:numstat_output) do
    <<~OUTPUT
      5\t2\tlib/foo.rb
      3\t1\tlib/bar.rb
       2 files changed, 8 insertions(+), 3 deletions(-)
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments (latest stash)' do
      it 'calls git stash show --numstat --shortstat -M' do
        expected_result = command_result(numstat_output)
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with specific stash reference' do
      it 'passes stash reference to command' do
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M', 'stash@{2}')
          .and_return(command_result(numstat_output))

        command.call('stash@{2}')
      end
    end

    context 'with :include_untracked option' do
      it 'adds --include-untracked flag when true' do
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M', '--include-untracked')
          .and_return(command_result(numstat_output))

        command.call(include_untracked: true)
      end

      it 'adds --no-include-untracked flag when false' do
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M', '--no-include-untracked')
          .and_return(command_result(numstat_output))

        command.call(include_untracked: false)
      end

      it 'accepts :u alias' do
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M', '--include-untracked')
          .and_return(command_result(numstat_output))

        command.call(u: true)
      end
    end

    context 'with :only_untracked option' do
      it 'adds --only-untracked flag' do
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M', '--only-untracked')
          .and_return(command_result(numstat_output))

        command.call(only_untracked: true)
      end
    end

    context 'with :dirstat option' do
      it 'adds --dirstat flag when true' do
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M', '--dirstat')
          .and_return(command_result(numstat_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect_command('stash', 'show', '--numstat', '--shortstat', '-M',
                       '--dirstat=lines,cumulative')
          .and_return(command_result(numstat_output))

        command.call(dirstat: 'lines,cumulative')
      end
    end
  end
end
