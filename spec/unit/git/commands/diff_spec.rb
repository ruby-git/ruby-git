# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff'

RSpec.describe Git::Commands::Diff do
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
      it 'runs git diff with no output-mode flags by default' do
        expected_result = command_result(numstat_output)
        expect_command_capturing('diff').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with output mode options' do
      it 'includes --patch when patch: true' do
        expect_command_capturing('diff', '--patch')
          .and_return(command_result(''))

        command.call(patch: true)
      end

      it 'includes --numstat when numstat: true' do
        expect_command_capturing('diff', '--numstat')
          .and_return(command_result(numstat_output))

        command.call(numstat: true)
      end

      it 'includes --raw when raw: true' do
        expect_command_capturing('diff', '--raw')
          .and_return(command_result(''))

        command.call(raw: true)
      end

      it 'includes --shortstat when shortstat: true' do
        expect_command_capturing('diff', '--shortstat')
          .and_return(command_result(''))

        command.call(shortstat: true)
      end

      it 'combines multiple output mode flags in DSL order' do
        expect_command_capturing('diff', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(numstat_output))

        command.call(patch: true, numstat: true, shortstat: true)
      end
    end

    context 'with prefix options (parser-contract args)' do
      it 'adds --src-prefix= when src_prefix: is given' do
        expect_command_capturing('diff', '--src-prefix=a/')
          .and_return(command_result(''))

        command.call(src_prefix: 'a/')
      end

      it 'adds --dst-prefix= when dst_prefix: is given' do
        expect_command_capturing('diff', '--dst-prefix=b/')
          .and_return(command_result(''))

        command.call(dst_prefix: 'b/')
      end

      it 'combines output mode flags with prefix options as facade would' do
        expect_command_capturing('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/')
          .and_return(command_result(numstat_output))

        command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with single commit (compare to HEAD)' do
      it 'passes the commit as an operand' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 'abc123').and_return(command_result(numstat_output))

        command.call('abc123', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with two commits (compare between commits)' do
      it 'passes both commits as operands' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', 'abc123',
                                 'def456').and_return(command_result(numstat_output))

        command.call('abc123', 'def456', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with three or more commits (combined diff of a merge commit)' do
      it 'passes all commits as operands' do
        expect_command_capturing('diff', '--merge-base', 'main', 'feature-a', 'feature-b')
          .and_return(command_result(''))

        command.call('main', 'feature-a', 'feature-b', merge_base: true)
      end
    end

    context 'with :cached option (staged changes)' do
      it 'includes the --cached flag' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 '--cached').and_return(command_result(numstat_output))

        command.call(cached: true, numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end

      it 'accepts :staged alias' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 '--cached').and_return(command_result(numstat_output))

        command.call(staged: true, numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with :merge_base option' do
      it 'includes the --merge-base flag with a single commit operand' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--merge-base',
                                 'feature').and_return(command_result(numstat_output))

        command.call('feature', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', merge_base: true)
      end

      it 'places --merge-base before both commit operands' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--merge-base',
                                 'main', 'feature').and_return(command_result(numstat_output))

        command.call('main', 'feature', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/',
                                        merge_base: true)
      end
    end

    context 'with :no_index option' do
      it 'passes paths via path: to emit -- separator' do
        expect_command_capturing('diff', '--patch', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--no-index',
                                 '--', '/path/a', '/path/b').and_return(command_result(''))

        command.call(patch: true, numstat: true, shortstat: true,
                     src_prefix: 'a/', dst_prefix: 'b/', no_index: true,
                     path: ['/path/a', '/path/b'])
      end

      it 'handles paths beginning with - safely via path:' do
        expect_command_capturing('diff', '--no-index', '--', '-weird-path', '/path/b')
          .and_return(command_result(''))

        command.call(no_index: true, path: ['-weird-path', '/path/b'])
      end
    end

    context 'with path limiting' do
      it 'adds paths after the -- separator' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--', 'lib/',
                                 'spec/').and_return(command_result(numstat_output))

        command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', pathspecs: ['lib/', 'spec/'])
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
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 '--dirstat').and_return(command_result(dirstat_output))

        result = command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', dirstat: true)

        expect(result.stdout).to include('62.5% lib/')
      end

      it 'passes dirstat options as an inline value' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 '--dirstat=lines,cumulative').and_return(command_result(dirstat_output))

        command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', dirstat: 'lines,cumulative')
      end
    end

    context 'exit code handling' do
      it 'returns successfully with exit code 0 when no differences' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/',
                                 '--dst-prefix=b/').and_return(command_result('', exitstatus: 0))

        result = command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns successfully with exit code 1 when differences found' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/',
                                 '--dst-prefix=b/').and_return(command_result(numstat_output, exitstatus: 1))

        result = command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).to eq(numstat_output)
      end

      it 'raises FailedError with exit code 2 (error)' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/')
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/') }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
