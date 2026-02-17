# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout/files'

RSpec.describe Git::Commands::Checkout::Files do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with nil tree_ish (restore from index)' do
      it 'omits tree_ish from command when nil' do
        expected_result = command_result
        expect_command('checkout', '--', 'file.txt').and_return(expected_result)

        result = command.call(nil, 'file.txt')

        expect(result).to eq(expected_result)
      end

      it 'restores multiple files from index' do
        expect_command('checkout', '--', 'file1.txt', 'file2.txt').and_return(command_result)
        command.call(nil, 'file1.txt', 'file2.txt')
      end

      it 'works with options' do
        expect_command('checkout', '--force', '--', 'file.txt').and_return(command_result)
        command.call(nil, 'file.txt', force: true)
      end
    end

    context 'with tree_ish and paths' do
      it 'places tree_ish before -- separator' do
        expect_command('checkout', 'HEAD~1', '--', 'file.txt').and_return(command_result)
        command.call('HEAD~1', 'file.txt')
      end

      it 'accepts branch name as tree_ish' do
        expect_command('checkout', 'main', '--', 'file.txt').and_return(command_result)
        command.call('main', 'file.txt')
      end

      it 'accepts commit SHA as tree_ish' do
        expect_command('checkout', 'abc123', '--', 'file.txt', 'other.txt').and_return(command_result)
        command.call('abc123', 'file.txt', 'other.txt')
      end

      it 'accepts tag as tree_ish' do
        expect_command('checkout', 'v1.0.0', '--', 'config.yml').and_return(command_result)
        command.call('v1.0.0', 'config.yml')
      end

      it 'accepts glob patterns' do
        expect_command('checkout', 'HEAD', '--', '*.rb').and_return(command_result)
        command.call('HEAD', '*.rb')
      end

      it 'accepts directory paths' do
        expect_command('checkout', 'HEAD', '--', 'src/').and_return(command_result)
        command.call('HEAD', 'src/')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect_command('checkout', '--force', 'HEAD', '--', 'file.txt').and_return(command_result)
        command.call('HEAD', 'file.txt', force: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'HEAD', '--', 'file.txt').and_return(command_result)
        command.call('HEAD', 'file.txt', force: false)
      end

      it 'works with :f alias' do
        expect_command('checkout', '--force', 'HEAD', '--', 'file.txt').and_return(command_result)
        command.call('HEAD', 'file.txt', f: true)
      end
    end

    context 'with :ours option (for merge conflicts)' do
      it 'adds --ours flag' do
        expect_command('checkout', '--ours', 'HEAD', '--', 'conflicted.txt').and_return(command_result)
        command.call('HEAD', 'conflicted.txt', ours: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'HEAD', '--', 'conflicted.txt').and_return(command_result)
        command.call('HEAD', 'conflicted.txt', ours: false)
      end
    end

    context 'with :theirs option (for merge conflicts)' do
      it 'adds --theirs flag' do
        expect_command('checkout', '--theirs', 'HEAD', '--', 'conflicted.txt').and_return(command_result)
        command.call('HEAD', 'conflicted.txt', theirs: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'HEAD', '--', 'conflicted.txt').and_return(command_result)
        command.call('HEAD', 'conflicted.txt', theirs: false)
      end
    end

    context 'with :merge option (recreate conflict markers)' do
      it 'adds --merge flag' do
        expect_command('checkout', '--merge', 'HEAD', '--', 'conflicted.txt').and_return(command_result)
        command.call('HEAD', 'conflicted.txt', merge: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'HEAD', '--', 'conflicted.txt').and_return(command_result)
        command.call('HEAD', 'conflicted.txt', merge: false)
      end

      it 'works with :m alias' do
        expect_command('checkout', '--merge', 'HEAD', '--', 'conflicted.txt').and_return(command_result)
        command.call('HEAD', 'conflicted.txt', m: true)
      end
    end

    context 'with :conflict option' do
      it 'adds --conflict=merge flag' do
        expect_command('checkout', '--conflict=merge', 'HEAD', '--', 'file.txt').and_return(command_result)
        command.call('HEAD', 'file.txt', conflict: 'merge')
      end

      it 'adds --conflict=diff3 flag' do
        expect_command('checkout', '--conflict=diff3', 'HEAD', '--', 'file.txt').and_return(command_result)
        command.call('HEAD', 'file.txt', conflict: 'diff3')
      end

      it 'adds --conflict=zdiff3 flag' do
        expect_command('checkout', '--conflict=zdiff3', 'HEAD', '--', 'file.txt').and_return(command_result)
        command.call('HEAD', 'file.txt', conflict: 'zdiff3')
      end
    end

    context 'with :overlay option' do
      it 'adds --overlay flag when true' do
        expect_command('checkout', '--overlay', 'main', '--', 'file.txt').and_return(command_result)
        command.call('main', 'file.txt', overlay: true)
      end

      it 'adds --no-overlay flag when false' do
        expect_command('checkout', '--no-overlay', 'main', '--', 'file.txt').and_return(command_result)
        command.call('main', 'file.txt', overlay: false)
      end
    end

    context 'with :pathspec_from_file option' do
      it 'adds --pathspec-from-file flag' do
        expect_command('checkout', '--pathspec-from-file=paths.txt', 'main').and_return(command_result)
        command.call('main', pathspec_from_file: 'paths.txt')
      end

      it 'accepts stdin with -' do
        expect_command('checkout', '--pathspec-from-file=-', 'HEAD').and_return(command_result)
        command.call('HEAD', pathspec_from_file: '-')
      end
    end

    context 'with :pathspec_file_nul option' do
      it 'adds --pathspec-file-nul flag with pathspec_from_file' do
        expect_command('checkout', '--pathspec-from-file=paths.txt', '--pathspec-file-nul',
                       'main').and_return(command_result)
        command.call('main', pathspec_from_file: 'paths.txt', pathspec_file_nul: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect_command('checkout',
                       '--force',
                       '--ours',
                       'HEAD',
                       '--',
                       'file1.txt',
                       'file2.txt').and_return(command_result)
        command.call('HEAD', 'file1.txt', 'file2.txt', force: true, ours: true)
      end

      it 'combines tree_ish with conflict resolution' do
        expect_command('checkout',
                       '--conflict=diff3',
                       'main',
                       '--',
                       'conflicted.txt').and_return(command_result)
        command.call('main', 'conflicted.txt', conflict: 'diff3')
      end
    end
  end
end
