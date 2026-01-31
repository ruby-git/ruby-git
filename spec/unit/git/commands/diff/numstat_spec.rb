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
      it 'calls git diff --numstat --shortstat -M' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call
      end

      it 'returns DiffResult with stats' do
        allow(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files_changed).to eq(2)
        expect(result.total_insertions).to eq(8)
        expect(result.total_deletions).to eq(3)
        expect(result.files.size).to eq(2)
        expect(result.dirstat).to be_nil
      end
    end

    context 'with single commit (compare to HEAD)' do
      it 'passes commit reference to command' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'abc123', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call('abc123')
      end
    end

    context 'with two commits (compare between commits)' do
      it 'passes both commit references to command' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'abc123', 'def456', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call('abc123', 'def456')
      end
    end

    context 'with merge-base syntax' do
      it 'passes the ... syntax directly' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'main...feature', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call('main...feature')
      end
    end

    context 'with :cached option (staged changes)' do
      it 'adds --cached flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--cached', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call(cached: true)
      end

      it 'accepts :staged alias' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--cached', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call(staged: true)
      end
    end

    context 'with :merge_base option' do
      it 'adds --merge-base flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--merge-base', 'feature', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call('feature', merge_base: true)
      end

      it 'works with two commits' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--merge-base', 'main', 'feature', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call('main', 'feature', merge_base: true)
      end
    end

    context 'with :no_index option' do
      it 'adds --no-index flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--no-index', '/path/a', '/path/b', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call('/path/a', '/path/b', no_index: true)
      end
    end

    context 'with pathspec limiting' do
      it 'adds pathspecs after -- separator' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--', 'lib/', 'spec/', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call(pathspecs: ['lib/', 'spec/'])
      end

      it 'works with commit and pathspecs' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', 'HEAD~3', '--', 'lib/', raise_on_failure: false)
          .and_return(command_result(numstat_output))

        command.call('HEAD~3', pathspecs: ['lib/'])
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

      it 'adds --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--dirstat', raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', '--dirstat=lines,cumulative', raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        command.call(dirstat: 'lines,cumulative')
      end
    end

    describe 'exit code handling' do
      it 'succeeds with exit code 0 (no differences)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files).to be_empty
      end

      it 'succeeds with exit code 1 (differences found)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(numstat_output, exitstatus: 1))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.size).to eq(2)
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
