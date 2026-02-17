# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/raw'

RSpec.describe Git::Commands::Diff::Raw do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  let(:raw_output) do
    <<~OUTPUT
      :100644 100644 abc1234 def5678 M\tlib/foo.rb
      :100644 100644 111aaaa 222bbbb M\tlib/bar.rb
      5\t2\tlib/foo.rb
      3\t1\tlib/bar.rb
       2 files changed, 8 insertions(+), 3 deletions(-)
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments (working tree vs index)' do
      it 'runs diff with --raw, --numstat, --shortstat, and -M flags' do
        expected_result = command_result(raw_output)
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with single commit' do
      it 'passes the commit as an operand' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', 'abc123')
          .and_return(command_result(raw_output))

        command.call('abc123')
      end
    end

    context 'with two commits' do
      it 'passes both commits as operands' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', 'abc123', 'def456')
          .and_return(command_result(raw_output))

        command.call('abc123', 'def456')
      end
    end

    context 'with :cached option' do
      it 'includes the --cached flag' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--cached')
          .and_return(command_result(raw_output))

        command.call(cached: true)
      end

      it 'accepts :staged alias' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--cached')
          .and_return(command_result(raw_output))

        command.call(staged: true)
      end
    end

    context 'with :find_copies option' do
      it 'includes the -C flag' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '-C')
          .and_return(command_result(raw_output))

        command.call(find_copies: true)
      end
    end

    context 'with :merge_base option' do
      it 'includes the --merge-base flag' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--merge-base', 'feature')
          .and_return(command_result(raw_output))

        command.call('feature', merge_base: true)
      end

      it 'includes --merge-base with two commits' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--merge-base', 'main', 'feature')
          .and_return(command_result(raw_output))

        command.call('main', 'feature', merge_base: true)
      end
    end

    context 'with :no_index option' do
      it 'includes the --no-index flag' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--no-index', '/path/a', '/path/b')
          .and_return(command_result(raw_output))

        command.call('/path/a', '/path/b', no_index: true)
      end
    end

    context 'with pathspec limiting' do
      it 'adds pathspecs after the -- separator' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--', 'lib/', 'spec/')
          .and_return(command_result(raw_output))

        command.call(pathspecs: ['lib/', 'spec/'])
      end

      it 'combines commit with pathspecs' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', 'HEAD~3', '--', 'lib/')
          .and_return(command_result(raw_output))

        command.call('HEAD~3', pathspecs: ['lib/'])
      end
    end

    context 'with :dirstat option' do
      let(:dirstat_output) do
        <<~OUTPUT
          :100644 100644 abc1234 def5678 M\tlib/foo.rb
          5\t2\tlib/foo.rb
           1 file changed, 5 insertions(+), 2 deletions(-)
            100.0% lib/
        OUTPUT
      end

      it 'includes the --dirstat flag when true' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--dirstat')
          .and_return(command_result(dirstat_output))

        result = command.call(dirstat: true)

        expect(result.stdout).to include('100.0% lib/')
      end

      it 'passes dirstat options when string' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M', '--dirstat=lines,cumulative')
          .and_return(command_result(dirstat_output))

        command.call(dirstat: 'lines,cumulative')
      end
    end

    context 'exit code handling' do
      it 'returns successfully with exit code 0 when no differences' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end

      it 'returns successfully with exit code 1 when differences found' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output, exitstatus: 1))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).to eq(raw_output)
      end

      it 'raises FailedError with exit code 2 (error)' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError with exit code 128 (git error)' do
        expect_command('diff', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
