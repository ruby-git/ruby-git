# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show_numstat'
require 'git/commands/stash/show_patch'
require 'git/commands/stash/show_raw'

# Integration tests for git stash show commands.
#
# These tests verify that the commands work correctly with real git repositories.
# Parsing edge cases (binary files, renames, special characters, etc.) are already
# covered by Diff::* integration tests since both use Git::Parsers::Diff.
#
# Focus here is on stash-specific behavior:
# - Basic stash show works
# - Stash reference formats (stash@{0}, 0)
# - --include-untracked option
# - --only-untracked option
#
RSpec.describe 'Git::Commands::Stash::Show*', :integration do
  include_context 'in an empty repository'

  before do
    # Create initial commit
    write_file('tracked.txt', "initial content\n")
    repo.add('tracked.txt')
    repo.commit('Initial commit')
  end

  describe Git::Commands::Stash::ShowNumstat do
    subject(:command) { described_class.new(execution_context) }

    context 'with a basic stash' do
      before do
        write_file('tracked.txt', "modified content\nmore lines\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns DiffResult with file statistics' do
        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files_changed).to eq(1)
        expect(result.files.first.path).to eq('tracked.txt')
        expect(result.files.first.insertions).to be > 0
      end

      it 'accepts stash reference as string' do
        result = command.call('stash@{0}')

        expect(result.files_changed).to eq(1)
      end

      it 'accepts stash index as string' do
        result = command.call('0')

        expect(result.files_changed).to eq(1)
      end
    end

    context 'with untracked files' do
      before do
        # Modify tracked file
        write_file('tracked.txt', "modified content\n")
        # Create untracked file
        write_file('untracked.txt', "new file content\n")
        # Stash with --include-untracked
        repo.lib.stash_save('WIP with untracked', include_untracked: true)
      end

      it 'shows only tracked files by default' do
        result = command.call

        paths = result.files.map(&:path)
        expect(paths).to include('tracked.txt')
        expect(paths).not_to include('untracked.txt')
      end

      it 'includes untracked files when include_untracked: true' do
        result = command.call(include_untracked: true)

        paths = result.files.map(&:path)
        expect(paths).to include('tracked.txt')
        expect(paths).to include('untracked.txt')
      end

      it 'shows only untracked files when only_untracked: true' do
        result = command.call(only_untracked: true)

        paths = result.files.map(&:path)
        expect(paths).not_to include('tracked.txt')
        expect(paths).to include('untracked.txt')
      end
    end

    context 'with multiple stashes' do
      before do
        # First stash - modify tracked file
        write_file('tracked.txt', "first modification\n")
        repo.lib.stash_save('First stash')

        # Second stash - add new tracked file
        write_file('another.txt', "another file\n")
        repo.add('another.txt')
        repo.lib.stash_save('Second stash')
      end

      it 'shows the latest stash by default' do
        result = command.call

        # Second stash should have another.txt
        paths = result.files.map(&:path)
        expect(paths).to include('another.txt')
      end

      it 'can show an older stash by index' do
        result = command.call('1')

        # First stash should have tracked.txt
        paths = result.files.map(&:path)
        expect(paths).to include('tracked.txt')
        expect(paths).not_to include('another.txt')
      end
    end
  end

  describe Git::Commands::Stash::ShowPatch do
    subject(:command) { described_class.new(execution_context) }

    context 'with a stash' do
      before do
        write_file('tracked.txt', "modified content\nmore lines\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns DiffResult with patch information' do
        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.first).to be_a(Git::DiffFilePatchInfo)
        expect(result.files.first.patch).to include('diff --git')
      end
    end
  end

  describe Git::Commands::Stash::ShowRaw do
    subject(:command) { described_class.new(execution_context) }

    context 'with a stash' do
      before do
        write_file('tracked.txt', "modified content\nmore lines\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns DiffResult with raw file information' do
        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.first).to be_a(Git::DiffFileRawInfo)
        expect(result.files.first.status).to eq(:modified)
      end
    end
  end
end
