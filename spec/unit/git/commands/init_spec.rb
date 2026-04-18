# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/init'

RSpec.describe Git::Commands::Init do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with default arguments' do
      it 'runs git init in the current directory' do
        expected_result = command_result
        expect_command_capturing('init').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a directory argument' do
      it 'initializes in the specified directory' do
        expect_command_capturing('init', '--', 'my-repo').and_return(command_result)

        command.call('my-repo')
      end
    end

    context 'with the :quiet option' do
      it 'includes the --quiet flag when true' do
        expect_command_capturing('init', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'does not include the flag when false' do
        expect_command_capturing('init').and_return(command_result)

        command.call(quiet: false)
      end
    end

    context 'with the :q alias' do
      it 'emits --quiet when :q is passed' do
        expect_command_capturing('init', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :bare option' do
      it 'includes the --bare flag when true' do
        expect_command_capturing('init', '--bare', '--', 'my-repo.git').and_return(command_result)

        command.call('my-repo.git', bare: true)
      end

      it 'does not include the flag when false' do
        expect_command_capturing('init', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', bare: false)
      end
    end

    context 'with the :template option' do
      it 'includes --template= with the specified path' do
        expect_command_capturing('init', '--template=/path/to/tpl', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', template: '/path/to/tpl')
      end
    end

    context 'with the :separate_git_dir option' do
      it 'uses --separate-git-dir= for the repository path' do
        expect_command_capturing('init', '--separate-git-dir=repo.git', '--', 'work').and_return(command_result)

        command.call('work', separate_git_dir: 'repo.git')
      end

      it 'raises ArgumentError for the old :repository option (backward compat is in Git::Lib#init)' do
        expect { command.call('work', repository: 'repo.git') }.to(
          raise_error(ArgumentError, /Unsupported options: :repository/)
        )
      end
    end

    context 'with the :object_format option' do
      it 'includes --object-format= with the specified value' do
        expect_command_capturing('init', '--object-format=sha256', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', object_format: 'sha256')
      end
    end

    context 'with the :ref_format option' do
      it 'includes --ref-format= with the specified value' do
        expect_command_capturing('init', '--ref-format=reftable', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', ref_format: 'reftable')
      end
    end

    context 'with the :initial_branch option' do
      it 'includes the --initial-branch= flag with the specified value' do
        expect_command_capturing('init', '--initial-branch=main', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', initial_branch: 'main')
      end

      it 'handles branch names with special characters' do
        expect_command_capturing(
          'init', '--initial-branch=feature/my-branch', '--', 'my-repo'
        ).and_return(command_result)

        command.call('my-repo', initial_branch: 'feature/my-branch')
      end
    end

    context 'with the :b alias' do
      it 'emits --initial-branch= when :b is passed' do
        expect_command_capturing('init', '--initial-branch=main', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', b: 'main')
      end
    end

    context 'with the :shared option' do
      it 'emits --shared when true' do
        expect_command_capturing('init', '--shared', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', shared: true)
      end

      it 'emits --shared=<value> when a string is passed' do
        expect_command_capturing('init', '--shared=group', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', shared: 'group')
      end

      it 'emits --shared= with octal permissions string' do
        expect_command_capturing('init', '--shared=0660', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', shared: '0660')
      end

      it 'does not include --shared when nil' do
        expect_command_capturing('init', '--', 'my-repo').and_return(command_result)

        command.call('my-repo', shared: nil)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect_command_capturing(
          'init', '--bare', '--initial-branch=develop', '--', 'bare.git'
        ).and_return(command_result)

        command.call('bare.git', bare: true, initial_branch: 'develop')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('my-repo', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end

      it 'raises ArgumentError for :log (handled by Git.init)' do
        expect { command.call('my-repo', log: double('Logger')) }.to(
          raise_error(ArgumentError, /Unsupported options: :log/)
        )
      end

      it 'raises ArgumentError for :git_ssh (handled by Git.init)' do
        expect { command.call('my-repo', git_ssh: '/path/to/ssh') }.to(
          raise_error(ArgumentError, /Unsupported options: :git_ssh/)
        )
      end
    end
  end
end
