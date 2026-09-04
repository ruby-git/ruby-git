# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'git/repository'
require 'git/repository/worktree_operations'

# worktree_add and worktree_prune are one-line delegators with no facade-owned
# post-processing. Baseline coverage for their happy paths comes from the command
# integration tests (spec/integration/git/commands/worktree/). Their integration
# tests below cover only real-git behaviors that need an unborn (no-commit)
# repository or multi-worktree state to reproduce.
#
# worktree_list and worktrees_all turn porcelain output into Ruby values; their
# integration tests verify that post-processing against actual git output,
# including a bare repository, which worktree_list reports and worktrees_all omits.
#
# worktree_remove, worktree_move, worktree_lock, worktree_unlock, and
# worktree_repair accept a Git::WorktreeInfo in place of a path; their integration
# tests verify that a Git::WorktreeInfo argument reaches git as the worktree path.
#
# worktree and worktrees are deprecated factory methods that construct domain
# objects (Git::Worktree and Git::Worktrees) without running git commands directly;
# they have no integration tests and are fully covered by the unit tests.

RSpec.describe Git::Repository::WorktreeOperations, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # A unique path for a linked worktree beside the test repository
  def new_worktree_path
    File.join(repo_dir, '..', "worktree-#{SecureRandom.hex(4)}")
  end

  # The Git::WorktreeInfo that worktree_list reports for the given path
  def info_for(path)
    described_instance.worktree_list.find { |info| info.path == File.realpath(path) }
  end

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#worktree_list' do
    context 'when only the main worktree exists' do
      it 'returns one Git::WorktreeInfo for the main worktree on its branch' do
        result = described_instance.worktree_list

        expect(result.size).to eq(1)
        expect(result.first).to be_a(Git::WorktreeInfo)
        expect(result.first).to have_attributes(
          path: File.realpath(repo_dir), branch: 'refs/heads/main', bare: false, detached: false,
          locked: false, prunable: false
        )
        expect(result.first.head).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'when a linked worktree has been added' do
      let(:worktree_path) { new_worktree_path }

      before { described_instance.worktree_add(worktree_path) }

      after { FileUtils.rm_rf(worktree_path) }

      it 'lists the main worktree first, followed by the linked worktree' do
        paths = described_instance.worktree_list.map(&:path)

        expect(paths).to eq([File.realpath(repo_dir), File.realpath(worktree_path)])
      end
    end

    context 'when the repository has no commits' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) { init_test_repo(unborn_repo_dir) }
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_repo.execution_context) }

      after { FileUtils.rm_rf(unborn_repo_dir) }

      it 'lists only the main worktree' do
        result = unborn_instance.worktree_list

        expect(result.size).to eq(1)
        expect(result.first.path).to eq(File.realpath(unborn_repo_dir))
      end
    end

    context 'when the repository is bare' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }
      let(:bare_instance) { Git::Repository.new(execution_context: Git.init(bare_dir, bare: true).execution_context) }

      after { FileUtils.rm_rf(bare_dir) }

      it 'includes the bare main worktree with a nil head and branch' do
        result = bare_instance.worktree_list

        expect(result.size).to eq(1)
        expect(result.first).to have_attributes(path: File.realpath(bare_dir), head: nil, branch: nil, bare: true)
      end
    end
  end

  describe '#worktrees_all' do
    it 'returns a [directory, sha] pair for each worktree reported by worktree_list' do
      infos = described_instance.worktree_list
      result = Git::Deprecation.silence { described_instance.worktrees_all }

      expect(result).to eq(infos.map { |info| [info.path, info.head] })
    end

    context 'when the repository is bare' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }
      let(:bare_instance) { Git::Repository.new(execution_context: Git.init(bare_dir, bare: true).execution_context) }

      after { FileUtils.rm_rf(bare_dir) }

      it 'omits the bare main worktree that worktree_list includes' do
        expect(bare_instance.worktree_list.size).to eq(1)
        expect(Git::Deprecation.silence { bare_instance.worktrees_all }).to eq([])
      end
    end
  end

  describe '#worktree_add' do
    context 'when the repository has no commits' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) { init_test_repo(unborn_repo_dir) }
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_repo.execution_context) }
      let(:worktree_path) { File.join(unborn_repo_dir, '..', "worktree-#{SecureRandom.hex(4)}") }

      after do
        FileUtils.rm_rf(unborn_repo_dir)
        FileUtils.rm_rf(worktree_path)
      end

      context 'on git versions before 2.42.0', if: Git.git_version < Git::Version.new(2, 42, 0) do
        it 'raises Git::FailedError' do
          expect { unborn_instance.worktree_add(worktree_path) }.to raise_error(Git::FailedError, /worktree/)
        end
      end

      context 'on git versions 2.42.0 and later', if: Git.git_version >= Git::Version.new(2, 42, 0) do
        it 'succeeds and creates a second worktree entry' do
          unborn_instance.worktree_add(worktree_path)

          expect(unborn_instance.worktree_list.size).to eq(2)
        end
      end
    end
  end

  describe '#worktree_remove' do
    let(:worktree_path) { new_worktree_path }

    before { described_instance.worktree_add(worktree_path) }

    after { FileUtils.rm_rf(worktree_path) }

    context 'when given a Git::WorktreeInfo' do
      it 'removes that worktree' do
        removed_path = File.realpath(worktree_path)

        described_instance.worktree_remove(info_for(worktree_path))

        expect(described_instance.worktree_list.map(&:path)).not_to include(removed_path)
      end
    end

    context 'when removing the main worktree' do
      it 'raises Git::FailedError and leaves all worktrees intact' do
        expect { described_instance.worktree_remove(File.realpath(repo_dir)) }
          .to raise_error(Git::FailedError, /main working tree/)

        expect(described_instance.worktree_list.size).to eq(2)
      end
    end
  end

  describe '#worktree_move' do
    let(:worktree_path) { new_worktree_path }
    let(:new_path) { new_worktree_path }

    before { described_instance.worktree_add(worktree_path) }

    after do
      FileUtils.rm_rf(worktree_path)
      FileUtils.rm_rf(new_path)
    end

    it 'moves the worktree to the new path' do
      old_path = File.realpath(worktree_path)

      described_instance.worktree_move(worktree_path, new_path)

      paths = described_instance.worktree_list.map(&:path)
      expect(paths).to include(File.realpath(new_path))
      expect(paths).not_to include(old_path)
    end

    context 'when given a Git::WorktreeInfo' do
      it 'moves that worktree to the new path' do
        described_instance.worktree_move(info_for(worktree_path), new_path)

        expect(described_instance.worktree_list.map(&:path)).to include(File.realpath(new_path))
      end
    end

    context 'when the worktree is locked' do
      before { described_instance.worktree_lock(worktree_path) }

      it 'moves the worktree when force is given twice' do
        described_instance.worktree_move(worktree_path, new_path, force: 2)

        expect(described_instance.worktree_list.map(&:path)).to include(File.realpath(new_path))
      end
    end

    context 'with an unsupported option' do
      it 'raises ArgumentError' do
        expect { described_instance.worktree_move(worktree_path, new_path, bogus: true) }
          .to raise_error(ArgumentError, /Unsupported options: :bogus/)
      end
    end
  end

  describe '#worktree_lock' do
    let(:worktree_path) { new_worktree_path }

    before { described_instance.worktree_add(worktree_path) }

    after { FileUtils.rm_rf(worktree_path) }

    it 'locks the worktree with no reason' do
      described_instance.worktree_lock(worktree_path)

      expect(info_for(worktree_path)).to have_attributes(locked: true, lock_reason: nil)
    end

    context 'with a reason' do
      it 'locks the worktree and records the reason' do
        described_instance.worktree_lock(worktree_path, reason: 'on purpose')

        expect(info_for(worktree_path)).to have_attributes(locked: true, lock_reason: 'on purpose')
      end
    end

    context 'when given a Git::WorktreeInfo' do
      it 'locks that worktree' do
        described_instance.worktree_lock(info_for(worktree_path))

        expect(info_for(worktree_path).locked?).to be true
      end
    end
  end

  describe '#worktree_unlock' do
    let(:worktree_path) { new_worktree_path }

    before do
      described_instance.worktree_add(worktree_path)
      described_instance.worktree_lock(worktree_path, reason: 'on purpose')
    end

    after { FileUtils.rm_rf(worktree_path) }

    it 'unlocks the worktree' do
      described_instance.worktree_unlock(worktree_path)

      expect(info_for(worktree_path)).to have_attributes(locked: false, lock_reason: nil)
    end

    context 'when given a Git::WorktreeInfo' do
      it 'unlocks that worktree' do
        described_instance.worktree_unlock(info_for(worktree_path))

        expect(info_for(worktree_path).locked?).to be false
      end
    end
  end

  describe '#worktree_repair' do
    context 'on git versions 2.29.0 and later', if: Git.git_version >= Git::Version.new(2, 29, 0) do
      let(:worktree_path) { new_worktree_path }
      let(:moved_path) { new_worktree_path }

      before do
        described_instance.worktree_add(worktree_path)
        FileUtils.mv(worktree_path, moved_path)
      end

      after do
        FileUtils.rm_rf(worktree_path)
        FileUtils.rm_rf(moved_path)
      end

      it 'reconnects a linked worktree that was moved without git' do
        described_instance.worktree_repair(moved_path)

        expect(described_instance.worktree_list.map(&:path)).to include(File.realpath(moved_path))
      end

      # With no paths, git repairs the link of the worktree at the current
      # directory rather than the one named by --git-dir, so the example passes
      # the moved path to keep the outcome independent of the test's cwd.
      it 'returns the output from git as a String' do
        expect(described_instance.worktree_repair(moved_path)).to be_a(String)
      end
    end

    context 'on git versions before 2.29.0', if: Git.git_version < Git::Version.new(2, 29, 0) do
      it 'raises Git::VersionError' do
        expect { described_instance.worktree_repair }.to raise_error(Git::VersionError, /2\.29\.0/)
      end
    end
  end

  describe '#worktree_prune' do
    context 'when a linked worktree has been manually deleted' do
      let(:worktree_path) { new_worktree_path }

      before do
        described_instance.worktree_add(worktree_path)
        FileUtils.rm_rf(worktree_path)
      end

      it 'removes the deleted worktree from the worktree list' do
        described_instance.worktree_prune

        expect(described_instance.worktree_list.size).to eq(1)
      end
    end
  end
end
