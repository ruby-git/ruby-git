# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/numstat'

RSpec.describe Git::Commands::Diff::Numstat do
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
    context 'with no arguments (working tree vs index)' do
      it 'runs diff with --numstat, --shortstat, and -M flags' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq(numstat_output)
      end
    end

    context 'with single commit (compare to HEAD)' do
      it 'passes the commit as an operand' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'abc123', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call('abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with two commits (compare between commits)' do
      it 'passes both commits as operands' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'abc123', 'def456', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call('abc123', 'def456')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with merge-base syntax' do
      it 'passes the triple-dot syntax directly' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'main...feature', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call('main...feature')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :cached option (staged changes)' do
      it 'includes the --cached flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--cached', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call(cached: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :staged alias' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--cached', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call(staged: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :merge_base option' do
      it 'includes the --merge-base flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--merge-base', 'feature', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call('feature', merge_base: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --merge-base with two commits' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--merge-base', 'main', 'feature', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call('main', 'feature', merge_base: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :no_index option' do
      it 'includes the --no-index flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--no-index', '/path/a', '/path/b', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call('/path/a', '/path/b', no_index: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with pathspec limiting' do
      it 'adds pathspecs after the -- separator' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--', 'lib/', 'spec/', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call(pathspecs: ['lib/', 'spec/'])

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'combines commit with pathspecs' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'HEAD~3', '--', 'lib/', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call('HEAD~3', pathspecs: ['lib/'])

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :dirstat option' do
      let(:dirstat_output) do
        <<~OUTPUT
          5\t2\tlib/foo.rb
          3\t1\tlib/bar.rb
           2 files changed, 8 insertions(+), 3 deletions(-)
            62.5% lib/
        OUTPUT
      end

      it 'includes the --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--dirstat', raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        result = command.call(dirstat: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to include('62.5% lib/')
      end

      it 'passes dirstat options as an inline value' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--dirstat=lines,cumulative', raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        result = command.call(dirstat: 'lines,cumulative')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'exit code handling' do
      it 'returns successfully with exit code 0 when no differences' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns successfully with exit code 1 when differences found' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(numstat_output, exitstatus: 1))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).to eq(numstat_output)
      end

      it 'raises FailedError with exit code 2 (error)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError with exit code 128 (git error)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
