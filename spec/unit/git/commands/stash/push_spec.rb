# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/push'

RSpec.describe Git::Commands::Stash::Push do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs stash push' do
        expect_command('stash', 'push').and_return(command_result(''))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
      end
    end

    context 'with :message option' do
      it 'adds -m flag with message' do
        expect_command('stash', 'push', '--message=WIP changes').and_return(command_result(''))
        command.call(message: 'WIP changes')
      end

      it 'accepts :m alias' do
        expect_command('stash', 'push', '--message=WIP').and_return(command_result(''))
        command.call(m: 'WIP')
      end

      it 'handles message with special characters' do
        expect_command('stash', 'push', '--message=Fix "bug" in code').and_return(command_result(''))
        command.call(message: 'Fix "bug" in code')
      end
    end

    context 'with :patch option' do
      it 'adds -p flag for interactive selection' do
        expect_command('stash', 'push', '--patch').and_return(command_result(''))
        command.call(patch: true)
      end

      it 'accepts :p alias' do
        expect_command('stash', 'push', '--patch').and_return(command_result(''))
        command.call(p: true)
      end

      it 'does not add flag when false' do
        expect_command('stash', 'push').and_return(command_result(''))
        command.call(patch: false)
      end
    end

    context 'with :staged option' do
      it 'adds -S flag to stash only staged changes' do
        expect_command('stash', 'push', '--staged').and_return(command_result(''))
        command.call(staged: true)
      end

      it 'accepts :S alias' do
        expect_command('stash', 'push', '--staged').and_return(command_result(''))
        command.call(S: true)
      end
    end

    context 'with :keep_index option' do
      it 'adds --keep-index flag when true' do
        expect_command('stash', 'push', '--keep-index').and_return(command_result(''))
        command.call(keep_index: true)
      end

      it 'adds --no-keep-index flag when false' do
        expect_command('stash', 'push', '--no-keep-index').and_return(command_result(''))
        command.call(keep_index: false)
      end

      it 'accepts :k alias' do
        expect_command('stash', 'push', '--keep-index').and_return(command_result(''))
        command.call(k: true)
      end
    end

    context 'with :include_untracked option' do
      it 'adds -u flag to include untracked files' do
        expect_command('stash', 'push', '--include-untracked').and_return(command_result(''))
        command.call(include_untracked: true)
      end

      it 'accepts :u alias' do
        expect_command('stash', 'push', '--include-untracked').and_return(command_result(''))
        command.call(u: true)
      end
    end

    context 'with :all option' do
      it 'adds -a flag to include ignored and untracked files' do
        expect_command('stash', 'push', '--all').and_return(command_result(''))
        command.call(all: true)
      end

      it 'accepts :a alias' do
        expect_command('stash', 'push', '--all').and_return(command_result(''))
        command.call(a: true)
      end
    end

    context 'with :pathspec_from_file option' do
      it 'adds --pathspec-from-file flag' do
        expect_command('stash', 'push', '--pathspec-from-file=paths.txt')
          .and_return(command_result(''))
        command.call(pathspec_from_file: 'paths.txt')
      end

      it 'supports reading from stdin with -' do
        expect_command('stash', 'push', '--pathspec-from-file=-').and_return(command_result(''))
        command.call(pathspec_from_file: '-')
      end
    end

    context 'with :pathspec_file_nul option' do
      it 'adds --pathspec-file-nul flag' do
        expect_command('stash', 'push', '--pathspec-from-file=paths.txt', '--pathspec-file-nul')
          .and_return(command_result(''))
        command.call(pathspec_from_file: 'paths.txt', pathspec_file_nul: true)
      end
    end

    context 'with paths (pathspecs)' do
      it 'adds paths after -- separator' do
        expect_command('stash', 'push', '--', 'file.txt').and_return(command_result(''))
        command.call('file.txt')
      end

      it 'accepts multiple paths' do
        expect_command('stash', 'push', '--', 'file1.txt', 'file2.txt').and_return(command_result(''))
        command.call('file1.txt', 'file2.txt')
      end

      it 'combines paths with options' do
        expect_command('stash', 'push', '--message=Partial stash', '--', 'src/')
          .and_return(command_result(''))
        command.call('src/', message: 'Partial stash')
      end
    end

    context 'with multiple options combined' do
      it 'combines keep_index with message' do
        expect_command('stash', 'push', '--keep-index', '--message=Testing')
          .and_return(command_result(''))
        command.call(keep_index: true, message: 'Testing')
      end

      it 'combines staged with paths' do
        expect_command('stash', 'push', '--staged', '--', 'src/', 'lib/')
          .and_return(command_result(''))
        command.call('src/', 'lib/', staged: true)
      end
    end
  end
end
