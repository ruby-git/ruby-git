# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/patch'

RSpec.describe Git::Commands::Diff::Patch do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Static args that Patch always includes for consistent prefix handling and rename detection
  let(:static_args) { ['diff', '--patch', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/', '-M'] }

  let(:patch_output) do
    <<~OUTPUT
      5\t2\tlib/foo.rb
       1 file changed, 5 insertions(+), 2 deletions(-)
      diff --git a/lib/foo.rb b/lib/foo.rb
      index abc1234..def5678 100644
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,3 +1,6 @@
       existing line
      +new line 1
      +new line 2
       another existing line
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments (working tree vs index)' do
      it 'calls git diff --patch --numstat --shortstat with prefix options' do
        expect(execution_context).to receive(:command)
          .with(*static_args, raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call
      end

      it 'returns DiffResult with patch file info' do
        allow(execution_context).to receive(:command)
          .with(*static_args, raise_on_failure: false)
          .and_return(command_result(patch_output))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files_changed).to eq(1)
        expect(result.total_insertions).to eq(5)
        expect(result.total_deletions).to eq(2)
        expect(result.files.size).to eq(1)
        expect(result.files[0]).to be_a(Git::DiffFilePatchInfo)
        expect(result.files[0].patch).to include('diff --git')
      end
    end

    context 'with single commit' do
      it 'passes commit reference to command' do
        expect(execution_context).to receive(:command)
          .with(*static_args, 'abc123', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call('abc123')
      end
    end

    context 'with two commits' do
      it 'passes both commit references to command' do
        expect(execution_context).to receive(:command)
          .with(*static_args, 'abc123', 'def456', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call('abc123', 'def456')
      end
    end

    context 'with :cached option' do
      it 'adds --cached flag' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--cached', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call(cached: true)
      end

      it 'accepts :staged alias' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--cached', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call(staged: true)
      end
    end

    context 'with :merge_base option' do
      it 'adds --merge-base flag' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--merge-base', 'feature', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call('feature', merge_base: true)
      end

      it 'works with two commits' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--merge-base', 'main', 'feature', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call('main', 'feature', merge_base: true)
      end
    end

    context 'with :no_index option' do
      it 'adds --no-index flag' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--no-index', '/path/a', '/path/b', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call('/path/a', '/path/b', no_index: true)
      end
    end

    context 'with pathspec limiting' do
      it 'adds pathspecs after -- separator' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--', 'lib/', 'spec/', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call(pathspecs: ['lib/', 'spec/'])
      end

      it 'works with commit and pathspecs' do
        expect(execution_context).to receive(:command)
          .with(*static_args, 'HEAD~3', '--', 'lib/', raise_on_failure: false)
          .and_return(command_result(patch_output))

        command.call('HEAD~3', pathspecs: ['lib/'])
      end
    end

    context 'with :dirstat option' do
      let(:dirstat_output) do
        <<~OUTPUT
          5\t2\tlib/foo.rb
           1 file changed, 5 insertions(+), 2 deletions(-)
            100.0% lib/
          diff --git a/lib/foo.rb b/lib/foo.rb
          index abc1234..def5678 100644
          --- a/lib/foo.rb
          +++ b/lib/foo.rb
          @@ -1,3 +1,6 @@
           existing line
          +new line
        OUTPUT
      end

      it 'adds --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--dirstat', raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect(execution_context).to receive(:command)
          .with(*static_args, '--dirstat=lines,cumulative', raise_on_failure: false)
          .and_return(command_result(dirstat_output))

        command.call(dirstat: 'lines,cumulative')
      end
    end

    describe 'exit code handling' do
      it 'succeeds with exit code 0 (no differences)' do
        expect(execution_context).to receive(:command)
          .with(*static_args, raise_on_failure: false)
          .and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files).to be_empty
      end

      it 'succeeds with exit code 1 (differences found)' do
        expect(execution_context).to receive(:command)
          .with(*static_args, raise_on_failure: false)
          .and_return(command_result(patch_output, exitstatus: 1))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.size).to eq(1)
      end

      it 'raises FailedError with exit code 2 (error)' do
        expect(execution_context).to receive(:command)
          .with(*static_args, raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError with exit code 128 (git error)' do
        expect(execution_context).to receive(:command)
          .with(*static_args, raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
