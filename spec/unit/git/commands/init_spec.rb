# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Init do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with default arguments' do
      it 'runs git init in the current directory' do
        expected_result = command_result
        expect_command('init').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a directory argument' do
      it 'initializes in the specified directory' do
        expect_command('init', 'my-repo').and_return(command_result)

        command.call('my-repo')
      end
    end

    context 'with the :bare option' do
      it 'includes the --bare flag when true' do
        expect_command('init', '--bare', 'my-repo.git').and_return(command_result)

        command.call('my-repo.git', bare: true)
      end

      it 'does not include the flag when false' do
        expect_command('init', 'my-repo').and_return(command_result)

        command.call('my-repo', bare: false)
      end
    end

    context 'with the :initial_branch option' do
      it 'includes the --initial-branch flag with the specified value' do
        expect_command('init', '--initial-branch=main', 'my-repo').and_return(command_result)

        command.call('my-repo', initial_branch: 'main')
      end

      it 'handles branch names with special characters' do
        expect_command('init', '--initial-branch=feature/my-branch', 'my-repo').and_return(command_result)

        command.call('my-repo', initial_branch: 'feature/my-branch')
      end
    end

    context 'with the :repository option' do
      it 'uses --separate-git-dir for the repository path' do
        # The repository path is passed through as-is (not expanded by the command)
        expect_command('init', '--separate-git-dir=repo.git', 'work').and_return(command_result)

        command.call('work', repository: 'repo.git')
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect_command('init', '--bare', '--initial-branch=develop', 'bare.git').and_return(command_result)

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
