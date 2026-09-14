# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/stashing'

# Single-command delegators (stash_apply, stash_pop, stash_drop, stash_show,
# stash_branch, stash_clear) are covered end-to-end by the command integration
# specs under spec/integration/git/commands/stash/. The examples here cover what
# those specs do not: the multi-command orchestration in stash_push and
# stash_store, the facade's own post-processing (stash_create), and a
# Git::StashInfo argument reaching git as its stash@{N} name.

RSpec.describe Git::Repository::Stashing, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('file.txt', 'initial content')
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#stash_list' do
    context 'when there are no stash entries' do
      it 'returns an empty array' do
        expect(described_instance.stash_list).to eq([])
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
        result = described_instance.stash_list

        expect(result).to all(be_a(Git::StashInfo))
        expect(result.map(&:name)).to eq(['stash@{0}', 'stash@{1}'])
        expect(result.map(&:index)).to eq([0, 1])
        expect(result.map(&:message)).to eq(['On main: second change', 'On main: first change'])
        expect(result.map(&:branch)).to eq(%w[main main])
      end

      it 'returns the same entries from the stash_infos alias' do
        expect(described_instance.stash_infos).to eq(described_instance.stash_list)
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
        expect(described_instance.stash_list.map(&:message)).to eq(['On main: newer work', 'On main: older work'])
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
        target = described_instance.stash_list.last

        described_instance.stash_apply(target)

        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq('change for stash 1')
        expect(described_instance.stash_list.size).to eq(2)
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
        target = described_instance.stash_list.last

        described_instance.stash_pop(target)

        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq('change for stash 1')
        expect(described_instance.stash_list.map(&:message)).to eq(['On main: second change'])
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
        target = described_instance.stash_list.last

        described_instance.stash_drop(target)

        expect(described_instance.stash_list.map(&:message)).to eq(['On main: second change'])
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
        target = described_instance.stash_list.last

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
        target = described_instance.stash_list.last

        described_instance.stash_branch('from-stash', target)

        expect(described_instance.current_branch).to eq('from-stash')
        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq('change for stash 1')
        expect(described_instance.stash_list.map(&:message)).to eq(['On main: second change'])
      end
    end
  end

  describe '#stash_create' do
    context 'when there are local changes' do
      before { write_file('file.txt', 'modified content') }

      it 'returns the object id of a stash commit without adding a stash entry' do
        result = described_instance.stash_create('created work')

        expect(result).to match(/\A[0-9a-f]{40}\z/)
        expect(described_instance.stash_list).to eq([])
      end
    end

    context 'when there are no local changes' do
      it 'returns nil' do
        expect(described_instance.stash_create).to be_nil
      end
    end
  end

  describe '#stash_store' do
    let(:oid) { described_instance.stash_create('created work') }

    before { write_file('file.txt', 'modified content') }

    it 'stores the commit and returns its entry' do
      result = described_instance.stash_store(oid, message: 'stored work')

      expect(result).to be_a(Git::StashInfo)
      expect(result).to have_attributes(name: 'stash@{0}', oid: oid, message: 'stored work')
    end

    it 'returns the existing top entry without adding one when the commit is already stash@{0}' do
      described_instance.stash_store(oid, message: 'first store')

      result = described_instance.stash_store(oid, message: 'second store')

      expect(result).to have_attributes(name: 'stash@{0}', oid: oid, message: 'first store')
      expect(described_instance.stash_list.size).to eq(1)
    end

    context 'when the commit is given as a revision other than the full object id' do
      it 'resolves an abbreviated object id' do
        result = described_instance.stash_store(oid[0, 7])
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'resolves an uppercase object id' do
        result = described_instance.stash_store(oid.upcase)
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'resolves a branch name' do
        repo.update_ref('wip', oid)
        result = described_instance.stash_store('wip')
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'resolves a full ref name outside refs/heads' do
        repo.update_ref('remotes/origin/wip', oid)
        result = described_instance.stash_store('refs/remotes/origin/wip')
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'resolves a :/<text> commit message search' do
        repo.update_ref('wip', oid)
        result = described_instance.stash_store(':/created work')
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'resolves a revision that already carries a ^{commit} suffix' do
        result = described_instance.stash_store("#{oid}^{commit}")
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'resolves a stash@{N} name to the same commit' do
        described_instance.stash_store(oid)
        result = described_instance.stash_store('stash@{0}')
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'resolves a Git::StashInfo through its String form' do
        entry = described_instance.stash_store(oid)
        result = described_instance.stash_store(entry)
        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
      end

      it 'stores the commit an annotated tag points to, not the tag object' do
        repo.tag_create('wip', oid, message: 'annotated')

        result = described_instance.stash_store('wip')

        expect(result).to have_attributes(name: 'stash@{0}', oid: oid)
        expect(repo.rev_parse('refs/stash')).to eq(oid)
      end
    end

    # These examples depart from the facade-test-conventions guidance against
    # error-path assertions in integration tests: stash_store resolves the commit
    # with `git rev-parse --verify` before storing it, and these examples pin
    # which forms of the argument that call rejects, with what message, and that
    # nothing is stored when it does. The nil, option-like, and negated cases
    # never reach git and are covered by the unit spec.
    context 'when the commit cannot be stored' do
      it 'raises Git::FailedError without storing anything when the commit is an empty string' do
        expect { described_instance.stash_store('') }.to raise_error(Git::FailedError, /Needed a single revision/)
        expect(described_instance.stash_list).to eq([])
      end

      it 'raises Git::FailedError without storing anything when the commit does not resolve' do
        expect { described_instance.stash_store('refs/nope') }
          .to raise_error(Git::FailedError, /Needed a single revision/)
        expect(described_instance.stash_list).to eq([])
      end

      it 'raises Git::FailedError without storing anything when given a range instead of a single commit' do
        expect { described_instance.stash_store("HEAD..#{oid}") }
          .to raise_error(Git::FailedError, /Needed a single revision/)
        expect(described_instance.stash_list).to eq([])
      end

      it 'raises Git::FailedError without storing anything when the revision does not peel to a commit' do
        expect { described_instance.stash_store('HEAD^{tree}') }
          .to raise_error(Git::FailedError, /expected commit type/)
        expect(described_instance.stash_list).to eq([])
      end

      it 'raises Git::FailedError naming the resolved id when the commit is not a stash commit' do
        head = repo.rev_parse('HEAD')

        expect { described_instance.stash_store('HEAD') }
          .to raise_error(Git::FailedError, /'#{head}' is not a stash-like commit/)
        expect(described_instance.stash_list).to eq([])
      end
    end
  end
end
