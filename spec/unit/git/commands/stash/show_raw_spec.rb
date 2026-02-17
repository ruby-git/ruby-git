# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show_raw'

RSpec.describe Git::Commands::Stash::ShowRaw do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Sample combined --raw, --numstat, and --shortstat output with rename detection
  let(:raw_output) do
    <<~OUTPUT
      :100644 100644 abc1234 def5678 M\tlib/foo.rb
      :000000 100644 0000000 1234567 A\tlib/bar.rb
      5\t2\tlib/foo.rb
      10\t0\tlib/bar.rb
       2 files changed, 15 insertions(+), 2 deletions(-)
    OUTPUT
  end

  let(:raw_output_with_rename) do
    <<~OUTPUT
      :100644 100644 abc1234 def5678 R075\told_name.rb\tnew_name.rb
      :000000 100644 0000000 1234567 A\tlib/bar.rb
      3\t1\tnew_name.rb
      10\t0\tlib/bar.rb
       2 files changed, 13 insertions(+), 1 deletion(-)
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments (latest stash)' do
      it 'calls git stash show --raw --numstat --shortstat -M' do
        expected_result = command_result(raw_output)
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with specific stash reference' do
      it 'passes stash reference to command' do
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', 'stash@{2}')
          .and_return(command_result(raw_output))

        command.call('stash@{2}')
      end
    end

    context 'with :include_untracked option' do
      it 'adds --include-untracked flag when true' do
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M',
                       '--include-untracked')
          .and_return(command_result(raw_output))

        command.call(include_untracked: true)
      end

      it 'adds --no-include-untracked flag when false' do
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M',
                       '--no-include-untracked')
          .and_return(command_result(raw_output))

        command.call(include_untracked: false)
      end
    end

    context 'with :only_untracked option' do
      it 'adds --only-untracked flag' do
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--only-untracked')
          .and_return(command_result(raw_output))

        command.call(only_untracked: true)
      end
    end

    context 'with :find_copies option' do
      it 'adds -C flag when true' do
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '-C')
          .and_return(command_result(raw_output))

        command.call(find_copies: true)
      end
    end

    context 'with :dirstat option' do
      it 'adds --dirstat flag when true' do
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--dirstat')
          .and_return(command_result(raw_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect_command('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--dirstat=files')
          .and_return(command_result(raw_output))

        command.call(dirstat: 'files')
      end
    end
  end
end
