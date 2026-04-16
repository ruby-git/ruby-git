# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_remote'

RSpec.describe Git::Commands::LsRemote do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments (queries the default remote)' do
      it 'runs git ls-remote with no positional arguments' do
        expected_result = command_result
        expect_command_capturing('ls-remote').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository argument' do
      it 'adds -- and the repository after options' do
        expect_command_capturing('ls-remote', '--', 'origin').and_return(command_result)

        command.call('origin')
      end
    end

    context 'with a repository and one pattern' do
      it 'adds -- and then repository and pattern' do
        expect_command_capturing('ls-remote', '--', 'origin', 'HEAD').and_return(command_result)

        command.call('origin', 'HEAD')
      end
    end

    context 'with a repository and multiple patterns' do
      it 'adds -- and then repository and all patterns' do
        expect_command_capturing('ls-remote', '--', 'origin', 'HEAD', 'refs/heads/*').and_return(command_result)

        command.call('origin', 'HEAD', 'refs/heads/*')
      end
    end

    context 'with patterns but no explicit repository' do
      it 'passes -- and then the pattern without a preceding repository' do
        expect_command_capturing('ls-remote', '--', 'HEAD').and_return(command_result)

        command.call(nil, 'HEAD')
      end
    end

    context 'with the :branches option' do
      it 'adds --branches to the command line' do
        expect_command_capturing('ls-remote', '--branches').and_return(command_result)

        command.call(branches: true)
      end

      it 'supports the :b alias' do
        expect_command_capturing('ls-remote', '--branches').and_return(command_result)

        command.call(b: true)
      end
    end

    context 'with the :heads option (deprecated backward-compat alias for :branches)' do
      it 'adds --heads to the command line' do
        expect_command_capturing('ls-remote', '--heads').and_return(command_result)

        command.call(heads: true)
      end

      it 'supports the :h alias' do
        expect_command_capturing('ls-remote', '--heads').and_return(command_result)

        command.call(h: true)
      end
    end

    context 'with the :tags option' do
      it 'adds --tags to the command line' do
        expect_command_capturing('ls-remote', '--tags').and_return(command_result)

        command.call(tags: true)
      end

      it 'supports the :t alias' do
        expect_command_capturing('ls-remote', '--tags').and_return(command_result)

        command.call(t: true)
      end
    end

    context 'with the :refs option' do
      it 'adds --refs to the command line' do
        expect_command_capturing('ls-remote', '--refs').and_return(command_result)

        command.call(refs: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('ls-remote', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('ls-remote', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :symref option' do
      it 'adds --symref to the command line' do
        expect_command_capturing('ls-remote', '--symref').and_return(command_result)

        command.call(symref: true)
      end
    end

    context 'with the :sort option' do
      it 'adds --sort=<key> to the command line' do
        expect_command_capturing('ls-remote', '--sort=version:refname').and_return(command_result)

        command.call(sort: 'version:refname')
      end
    end

    context 'with the :exit_code option' do
      it 'adds --exit-code to the command line' do
        expect_command_capturing('ls-remote', '--exit-code').and_return(command_result)

        command.call(exit_code: true)
      end
    end

    context 'with the :get_url option' do
      it 'adds --get-url to the command line' do
        expect_command_capturing('ls-remote', '--get-url').and_return(command_result)

        command.call(get_url: true)
      end
    end

    context 'with the :upload_pack option' do
      it 'adds --upload-pack=<exec> to the command line' do
        expect_command_capturing('ls-remote',
                                 '--upload-pack=/usr/lib/git-core/git-upload-pack').and_return(command_result)

        command.call(upload_pack: '/usr/lib/git-core/git-upload-pack')
      end
    end

    context 'with the :server_option option' do
      it 'adds --server-option=<option> to the command line' do
        expect_command_capturing('ls-remote', '--server-option=version=2').and_return(command_result)

        command.call(server_option: 'version=2')
      end

      it 'supports the :o alias' do
        expect_command_capturing('ls-remote', '--server-option=version=2').and_return(command_result)

        command.call(o: 'version=2')
      end

      it 'accepts multiple server options as an array' do
        expect_command_capturing('ls-remote', '--server-option=a', '--server-option=b').and_return(command_result)

        command.call(server_option: %w[a b])
      end
    end

    context 'with multiple options and a repository' do
      it 'emits flags before end-of-options and repository after' do
        expect_command_capturing(
          'ls-remote', '--branches', '--tags', '--refs', '--', 'origin'
        ).and_return(command_result)

        command.call('origin', branches: true, tags: true, refs: true)
      end
    end

    context 'with a timeout execution option' do
      it 'passes the timeout to the execution context' do
        expect_command_capturing('ls-remote', '--', 'origin', timeout: 30).and_return(command_result)

        command.call('origin', timeout: 30)
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 0' do
        allow(execution_context).to receive(:command_capturing)
          .with('ls-remote', raise_on_failure: false)
          .and_return(command_result(exitstatus: 0))

        result = command.call

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns result for exit code 1' do
        allow(execution_context).to receive(:command_capturing)
          .with('ls-remote', raise_on_failure: false)
          .and_return(command_result(exitstatus: 1))

        result = command.call

        expect(result.status.exitstatus).to eq(1)
      end

      it 'returns result for exit code 2' do
        allow(execution_context).to receive(:command_capturing)
          .with('ls-remote', raise_on_failure: false)
          .and_return(command_result(exitstatus: 2))

        result = command.call

        expect(result.status.exitstatus).to eq(2)
      end

      it 'raises FailedError for exit code 3 (outside allowed range)' do
        allow(execution_context).to receive(:command_capturing)
          .with('ls-remote', raise_on_failure: false)
          .and_return(command_result('', stderr: 'fatal: error', exitstatus: 3))

        expect { command.call }.to raise_error(Git::FailedError, /fatal: error/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown_option: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
