# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/stashing'

# Single-command delegators (stash_apply, stash_pop, stash_drop, stash_show,
# stash_branch, stash_clear) are covered end-to-end by the command integration
# specs under spec/integration/git/commands/stash/. The examples here cover what
# those specs do not: the multi-command orchestration in stash_push and
# stash_store, the facade's own post-processing (stash_create, stashes_all), and a
# Git::StashInfo argument reaching git as its stash@{N} name.

RSpec.describe Git::Repository::Stashing, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('file.txt', 'initial content')
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#stash_infos' do
    context 'when there are no stash entries' do
      it 'returns an empty array' do
        expect(described_instance.stash_infos).to eq([])
      end
    end

    context 'when there are multiple stash entries' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_push(message: 'first change')

        write_file('file.txt', 'change for stash 2')
        repo.stash_push(message: 'second change')
      end

      it 'returns Git::StashInfo entries newest first with git indices and full messages' do
        result = described_instance.stash_infos

        expect(result).to all(be_a(Git::StashInfo))
        expect(result.map(&:name)).to eq(['stash@{0}', 'stash@{1}'])
        expect(result.map(&:index)).to eq([0, 1])
        expect(result.map(&:message)).to eq(['On main: second change', 'On main: first change'])
        expect(result.map(&:branch)).to eq(%w[main main])
      end
    end
  end

  describe '#stash_push' do
    context 'when there are local changes to save' do
      before { write_file('file.txt', 'modified content') }

      it 'returns the new Git::StashInfo entry' do
        result = described_instance.stash_push(message: 'my feature work')

        expect(result).to be_a(Git::StashInfo)
        expect(result).to have_attributes(name: 'stash@{0}', message: 'On main: my feature work', branch: 'main')
      end

      it 'returns the new entry rather than an older one when entries already exist' do
        described_instance.stash_push(message: 'older work')
        write_file('file.txt', 'newer content')

        result = described_instance.stash_push(message: 'newer work')

        expect(result).to have_attributes(name: 'stash@{0}', message: 'On main: newer work')
        expect(described_instance.stash_infos.map(&:message)).to eq(['On main: newer work', 'On main: older work'])
      end

      it 'accepts the options as a positional Hash' do
        opts = { message: 'my feature work' }

        result = described_instance.stash_push(opts)

        expect(result).to have_attributes(name: 'stash@{0}', message: 'On main: my feature work')
      end
    end

    context 'when there are no local changes to save' do
      it 'returns nil' do
        expect(described_instance.stash_push(message: 'nothing to save')).to be_nil
      end

      it 'returns nil with quiet: true when an entry already exists' do
        write_file('file.txt', 'modified content')
        described_instance.stash_push(message: 'existing work')

        expect(described_instance.stash_push(message: 'nothing to save', quiet: true)).to be_nil
      end
    end
  end

  describe '#stash_apply' do
    context 'when given a Git::StashInfo' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_push(message: 'first change')
        write_file('file.txt', 'change for stash 2')
        repo.stash_push(message: 'second change')
      end

      it 'applies that entry and keeps it in the stash list' do
        target = described_instance.stash_infos.last

        described_instance.stash_apply(target)

        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq('change for stash 1')
        expect(described_instance.stash_infos.size).to eq(2)
      end
    end
  end

  describe '#stash_pop' do
    context 'when given a Git::StashInfo' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_push(message: 'first change')
        write_file('file.txt', 'change for stash 2')
        repo.stash_push(message: 'second change')
      end

      it 'applies that entry and removes it from the stash list' do
        target = described_instance.stash_infos.last

        described_instance.stash_pop(target)

        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq('change for stash 1')
        expect(described_instance.stash_infos.map(&:message)).to eq(['On main: second change'])
      end
    end
  end

  describe '#stash_drop' do
    context 'when given a Git::StashInfo' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_push(message: 'first change')
        write_file('file.txt', 'change for stash 2')
        repo.stash_push(message: 'second change')
      end

      it 'removes that entry from the stash list' do
        target = described_instance.stash_infos.last

        described_instance.stash_drop(target)

        expect(described_instance.stash_infos.map(&:message)).to eq(['On main: second change'])
      end
    end
  end

  describe '#stash_show' do
    context 'when given a Git::StashInfo' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_push(message: 'first change')
        write_file('other.txt', 'unrelated')
        repo.add('other.txt')
        repo.stash_push(message: 'second change')
      end

      it 'shows the files changed by that entry' do
        target = described_instance.stash_infos.last

        result = described_instance.stash_show(target)

        expect(result).to include('file.txt')
        expect(result).not_to include('other.txt')
      end
    end
  end

  describe '#stash_branch' do
    context 'when given a Git::StashInfo' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_push(message: 'first change')
        write_file('file.txt', 'change for stash 2')
        repo.stash_push(message: 'second change')
      end

      it 'creates the branch from that entry and drops it' do
        target = described_instance.stash_infos.last

        described_instance.stash_branch('from-stash', target)

        expect(described_instance.current_branch).to eq('from-stash')
        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq('change for stash 1')
        expect(described_instance.stash_infos.map(&:message)).to eq(['On main: second change'])
      end
    end
  end

  describe '#stash_create' do
    context 'when there are local changes' do
      before { write_file('file.txt', 'modified content') }

      it 'returns the object id of a stash commit without adding a stash entry' do
        result = described_instance.stash_create('created work')

        expect(result).to match(/\A[0-9a-f]{40}\z/)
        expect(described_instance.stash_infos).to eq([])
      end
    end

    context 'when there are no local changes' do
      it 'returns nil' do
        expect(described_instance.stash_create).to be_nil
      end
    end
  end

  describe '#stash_store' do
    before { write_file('file.txt', 'modified content') }

    it 'returns the stored entry from the top of the stash list' do
      oid = described_instance.stash_create('created work')

      result = described_instance.stash_store(oid, message: 'stored work')

      expect(result).to be_a(Git::StashInfo)
      expect(result).to have_attributes(name: 'stash@{0}', oid: oid, message: 'stored work')
    end
  end

  describe '#stashes_all' do
    before { allow(Git::Deprecation).to receive(:warn) }

    context 'when there are no stash entries' do
      it 'returns an empty array' do
        expect(described_instance.stashes_all).to eq([])
      end
    end

    context 'when there is one stash entry with a branch prefix' do
      before do
        write_file('file.txt', 'modified content')
        repo.stash_push(message: 'my feature work')
      end

      it 'strips the branch prefix from the message' do
        result = described_instance.stashes_all
        # Git prefixes the message: "On main: my feature work"
        # The facade strips the "On main:" prefix
        expect(result.first.last).to eq('my feature work')
      end
    end

    context 'when there are multiple stash entries' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_push(message: 'first change')

        write_file('file.txt', 'change for stash 2')
        repo.stash_push(message: 'second change')
      end

      it 'returns entries in oldest-first order' do
        result = described_instance.stashes_all

        expect(result.length).to eq(2)
        expect(result.map(&:first)).to eq([0, 1])
        expect(result.map(&:last)).to eq(['first change', 'second change'])
      end
    end

    context 'when a stash message contains a colon (e.g. "saving: work")' do
      before do
        write_file('file.txt', 'modified content')
        repo.stash_push(message: 'saving: work')
      end

      it 'strips only the branch prefix and keeps the rest of the message' do
        result = described_instance.stashes_all
        # Git stores: "On main: saving: work"; facade strips "On main:" => "saving: work"
        expect(result.first.last).to eq('saving: work')
      end
    end

    context 'when the stash was created from a detached HEAD' do
      before do
        sha = repo.log(1).execute.first.sha
        repo.checkout(sha)
        write_file('file.txt', 'detached change')
        repo.stash_push(message: 'detached stash')
      end

      it 'returns the stash message without a branch prefix' do
        result = described_instance.stashes_all
        # Git stores detached-HEAD stashes as "On (no branch): <message>"; the facade strips that prefix too
        expect(result.first).to eq([0, 'detached stash'])
      end
    end
  end

  describe '#stash_list' do
    before do
      write_file('file.txt', 'modified content')
      repo.add('file.txt')
      repo.stash_push(message: 'WIP')
    end

    it 'emits a deprecation warning' do
      expect(Git::Deprecation).to receive(:warn).with(a_string_including('stash_list'))
      described_instance.stash_list
    end

    it 'contains "stash@{0}"' do
      allow(Git::Deprecation).to receive(:warn)
      expect(described_instance.stash_list).to include('stash@{0}')
    end

    it 'contains the stash message' do
      allow(Git::Deprecation).to receive(:warn)
      expect(described_instance.stash_list).to include('WIP')
    end
  end
end
