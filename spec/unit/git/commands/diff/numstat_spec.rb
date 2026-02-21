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
        expected_result = command_result(numstat_output)
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/',
                       '--dst-prefix=b/').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with single commit (compare to HEAD)' do
      it 'passes the commit as an operand' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/',
                       'abc123').and_return(command_result(numstat_output))

        command.call('abc123')
      end
    end

    context 'with two commits (compare between commits)' do
      it 'passes both commits as operands' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/', 'abc123',
                       'def456').and_return(command_result(numstat_output))

        command.call('abc123', 'def456')
      end
    end

    context 'with merge-base syntax' do
      it 'passes the triple-dot syntax directly' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/',
                       'main...feature').and_return(command_result(numstat_output))

        command.call('main...feature')
      end
    end

    context 'with :cached option (staged changes)' do
      it 'includes the --cached flag' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/',
                       '--cached').and_return(command_result(numstat_output))

        command.call(cached: true)
      end

      it 'accepts :staged alias' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/',
                       '--cached').and_return(command_result(numstat_output))

        command.call(staged: true)
      end
    end

    context 'with :merge_base option' do
      it 'includes the --merge-base flag' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/', '--merge-base',
                       'feature').and_return(command_result(numstat_output))

        command.call('feature', merge_base: true)
      end

      it 'includes --merge-base with two commits' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/', '--merge-base', 'main',
                       'feature').and_return(command_result(numstat_output))

        command.call('main', 'feature', merge_base: true)
      end
    end

    context 'with :no_index option' do
      it 'includes the --no-index flag' do
        expect_command('diff', '--numstat', '--shortstat',
                       '--src-prefix=a/', '--dst-prefix=b/', '--no-index',
                       '/path/a', '/path/b').and_return(command_result(numstat_output))

        command.call('/path/a', '/path/b', no_index: true)
      end
    end

    context 'with pathspec limiting' do
      it 'adds pathspecs after the -- separator' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/', '--', 'lib/',
                       'spec/').and_return(command_result(numstat_output))

        command.call(pathspecs: ['lib/', 'spec/'])
      end

      it 'combines commit with pathspecs' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/', 'HEAD~3', '--',
                       'lib/').and_return(command_result(numstat_output))

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

      it 'includes the --dirstat flag when true' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/',
                       '--dirstat').and_return(command_result(dirstat_output))

        result = command.call(dirstat: true)

        expect(result.stdout).to include('62.5% lib/')
      end

      it 'passes dirstat options as an inline value' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/',
                       '--dirstat=lines,cumulative').and_return(command_result(dirstat_output))

        command.call(dirstat: 'lines,cumulative')
      end
    end

    context 'exit code handling' do
      it 'returns successfully with exit code 0 when no differences' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/',
                       '--dst-prefix=b/').and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns successfully with exit code 1 when differences found' do
        expect_command('diff', '--numstat', '--shortstat', '--src-prefix=a/',
                       '--dst-prefix=b/').and_return(command_result(numstat_output, exitstatus: 1))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).to eq(numstat_output)
      end

      it 'raises FailedError with exit code 2 (error)' do
        expect_command('diff', '--numstat', '--shortstat',
                       '--src-prefix=a/', '--dst-prefix=b/')
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError with exit code 128 (git error)' do
        expect_command('diff', '--numstat', '--shortstat',
                       '--src-prefix=a/', '--dst-prefix=b/')
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
