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
      it 'calls git diff --raw --numstat --shortstat -M' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call
      end

      it 'returns DiffResult with raw file info' do
        allow(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(raw_output))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files_changed).to eq(2)
        expect(result.total_insertions).to eq(8)
        expect(result.total_deletions).to eq(3)
        expect(result.files.size).to eq(2)
        expect(result.files[0]).to be_a(Git::DiffFileRawInfo)
      end
    end

    context 'with single commit' do
      it 'passes commit reference to command' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', 'abc123', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call('abc123')
      end
    end

    context 'with two commits' do
      it 'passes both commit references to command' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', 'abc123', 'def456', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call('abc123', 'def456')
      end
    end

    context 'with :cached option' do
      it 'adds --cached flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--cached', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call(cached: true)
      end

      it 'accepts :staged alias' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--cached', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call(staged: true)
      end
    end

    context 'with :find_copies option' do
      it 'adds -C flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '-C', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call(find_copies: true)
      end
    end

    context 'with :merge_base option' do
      it 'adds --merge-base flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--merge-base', 'feature', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call('feature', merge_base: true)
      end

      it 'works with two commits' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--merge-base', 'main', 'feature',
                raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call('main', 'feature', merge_base: true)
      end
    end

    context 'with :no_index option' do
      it 'adds --no-index flag' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--no-index', '/path/a', '/path/b',
                raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call('/path/a', '/path/b', no_index: true)
      end
    end

    context 'with pathspec limiting' do
      it 'adds pathspecs after -- separator' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--', 'lib/', 'spec/', raise_on_failure: false)
          .and_return(command_result(raw_output))

        command.call(pathspecs: ['lib/', 'spec/'])
      end

      it 'works with commit and pathspecs' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', 'HEAD~3', '--', 'lib/', raise_on_failure: false)
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

      it 'adds --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--dirstat', raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', '--dirstat=lines,cumulative',
                raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        command.call(dirstat: 'lines,cumulative')
      end
    end

    describe 'exit code handling' do
      it 'succeeds with exit code 0 (no differences)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files).to be_empty
      end

      it 'succeeds with exit code 1 (differences found)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result(raw_output, exitstatus: 1))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.size).to eq(2)
      end

      it 'raises FailedError with exit code 2 (error)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError with exit code 128 (git error)' do
        expect(execution_context).to receive(:command)
          .with('diff', '--raw', '--numstat', '--shortstat', '-M', raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
