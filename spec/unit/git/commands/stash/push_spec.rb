# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/push'
require 'git/commands/stash/list'
require 'git/stash_info'

RSpec.describe Git::Commands::Stash::Push do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:stash_info) do
    Git::StashInfo.new(
      index: 0, name: 'stash@{0}', sha: 'abc123', short_sha: 'abc123',
      branch: 'main', message: 'WIP on main: test',
      author_name: 'Test', author_email: 'test@example.com', author_date: '2024-01-01',
      committer_name: 'Test', committer_email: 'test@example.com', committer_date: '2024-01-01'
    )
  end
  let(:list_command) { instance_double(Git::Commands::Stash::List) }

  before do
    allow(Git::Commands::Stash::List).to receive(:new).with(execution_context).and_return(list_command)
    allow(list_command).to receive(:call).and_return([stash_info])
  end

  describe '#call' do
    context 'with no arguments' do
      it 'calls git stash push' do
        expect(execution_context).to receive(:command).with('stash', 'push').and_return('')
        command.call
      end

      it 'returns the new StashInfo' do
        allow(execution_context).to receive(:command).with('stash', 'push').and_return('')
        expect(command.call).to eq(stash_info)
      end
    end

    context 'when nothing to stash' do
      it 'returns nil' do
        allow(execution_context).to receive(:command).with('stash', 'push').and_return('No local changes to save')
        expect(command.call).to be_nil
      end
    end

    context 'with :message option' do
      it 'adds -m flag with message' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--message=WIP changes').and_return('')
        command.call(message: 'WIP changes')
      end

      it 'accepts :m alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--message=WIP').and_return('')
        command.call(m: 'WIP')
      end

      it 'handles message with special characters' do
        expect(execution_context).to receive(:command)
          .with('stash', 'push', '--message=Fix "bug" in code').and_return('')
        command.call(message: 'Fix "bug" in code')
      end
    end

    context 'with :patch option' do
      it 'adds -p flag for interactive selection' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--patch').and_return('')
        command.call(patch: true)
      end

      it 'accepts :p alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--patch').and_return('')
        command.call(p: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('stash', 'push').and_return('')
        command.call(patch: false)
      end
    end

    context 'with :staged option' do
      it 'adds -S flag to stash only staged changes' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--staged').and_return('')
        command.call(staged: true)
      end

      it 'accepts :S alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--staged').and_return('')
        command.call(S: true)
      end
    end

    context 'with :keep_index option' do
      it 'adds --keep-index flag when true' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--keep-index').and_return('')
        command.call(keep_index: true)
      end

      it 'adds --no-keep-index flag when false' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--no-keep-index').and_return('')
        command.call(keep_index: false)
      end

      it 'accepts :k alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--keep-index').and_return('')
        command.call(k: true)
      end
    end

    context 'with :include_untracked option' do
      it 'adds -u flag to include untracked files' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--include-untracked').and_return('')
        command.call(include_untracked: true)
      end

      it 'accepts :u alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--include-untracked').and_return('')
        command.call(u: true)
      end
    end

    context 'with :all option' do
      it 'adds -a flag to include ignored and untracked files' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--all').and_return('')
        command.call(all: true)
      end

      it 'accepts :a alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--all').and_return('')
        command.call(a: true)
      end
    end

    context 'with :pathspec_from_file option' do
      it 'adds --pathspec-from-file flag' do
        expect(execution_context).to receive(:command)
          .with('stash', 'push', '--pathspec-from-file=paths.txt').and_return('')
        command.call(pathspec_from_file: 'paths.txt')
      end

      it 'supports reading from stdin with -' do
        expect(execution_context).to receive(:command)
          .with('stash', 'push', '--pathspec-from-file=-').and_return('')
        command.call(pathspec_from_file: '-')
      end
    end

    context 'with :pathspec_file_nul option' do
      it 'adds --pathspec-file-nul flag' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--pathspec-from-file=paths.txt', '--pathspec-file-nul'
        ).and_return('')
        command.call(pathspec_from_file: 'paths.txt', pathspec_file_nul: true)
      end
    end

    context 'with paths (pathspecs)' do
      it 'adds paths after -- separator' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--', 'file.txt').and_return('')
        command.call('file.txt')
      end

      it 'accepts multiple paths' do
        expect(execution_context).to receive(:command)
          .with('stash', 'push', '--', 'file1.txt', 'file2.txt').and_return('')
        command.call('file1.txt', 'file2.txt')
      end

      it 'combines paths with options' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--message=Partial stash', '--', 'src/'
        ).and_return('')
        command.call('src/', message: 'Partial stash')
      end
    end

    context 'with multiple options combined' do
      it 'combines keep_index with message' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--keep-index', '--message=Testing'
        ).and_return('')
        command.call(keep_index: true, message: 'Testing')
      end

      it 'combines staged with paths' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--staged', '--', 'src/', 'lib/'
        ).and_return('')
        command.call('src/', 'lib/', staged: true)
      end
    end
  end
end
