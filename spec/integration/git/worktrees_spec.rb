# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

RSpec.describe Git::Worktrees, :integration do
  include_context 'in an empty repository'

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  # ---------------------------------------------------------------------------
  # Git::Base constructor path: Git::Base#worktrees passes self (a Git::Base)
  # ---------------------------------------------------------------------------

  context 'when initialized via Git::Base (Git::Base passed to constructor)' do
    let(:worktrees) { repo.worktrees }

    describe '#size' do
      it 'returns 1 for a repository with only the main worktree' do
        expect(worktrees.size).to eq(1)
      end
    end

    describe '#each' do
      it 'yields Git::Worktree objects' do
        expect(worktrees.to_a).to all(be_a(Git::Worktree))
      end

      it 'includes the main worktree directory' do
        expect(worktrees.map(&:dir)).to include(File.realpath(repo_dir))
      end
    end

    describe '#[]' do
      it 'finds the main worktree by its filesystem path' do
        result = worktrees[File.realpath(repo_dir)]
        expect(result).to be_a(Git::Worktree)
        expect(result.dir).to eq(File.realpath(repo_dir))
      end

      it 'returns nil for a path that does not correspond to any worktree' do
        expect(worktrees['/no/such/worktree/path']).to be_nil
      end
    end

    describe '#to_s' do
      it 'includes the main worktree path in the listing' do
        expect(worktrees.to_s).to include(File.realpath(repo_dir))
      end
    end

    context 'with a linked worktree' do
      let(:linked_path) do
        File.join(File.dirname(File.realpath(repo_dir)), "wt-#{SecureRandom.hex(4)}")
      end

      before do
        repo.worktree(linked_path).add
      end

      after do
        repo.worktree(linked_path).remove
      ensure
        FileUtils.rm_rf(linked_path)
        repo.worktrees.prune
      end

      describe '#size' do
        it 'returns 2 when a linked worktree has been added' do
          expect(repo.worktrees.size).to eq(2)
        end
      end

      describe '#each' do
        it 'yields both the main and linked worktrees' do
          dirs = repo.worktrees.map(&:dir)
          expect(dirs).to include(File.realpath(repo_dir), linked_path)
        end
      end

      describe '#[]' do
        it 'finds the linked worktree by its filesystem path' do
          result = repo.worktrees[linked_path]
          expect(result).to be_a(Git::Worktree)
          expect(result.dir).to eq(linked_path)
        end
      end
    end

    describe '#prune' do
      let(:linked_path) do
        File.join(File.dirname(File.realpath(repo_dir)), "wt-#{SecureRandom.hex(4)}")
      end

      before do
        repo.worktree(linked_path).add
      end

      after do
        FileUtils.rm_rf(linked_path)
      end

      it 'removes administrative files for worktrees whose directories no longer exist' do
        expect(repo.worktrees.size).to eq(2)

        # Simulate a stale worktree by deleting the directory without running
        # git worktree remove
        FileUtils.rm_rf(linked_path)

        repo.worktrees.prune

        # A freshly constructed collection must now contain only the main worktree
        expect(repo.worktrees.size).to eq(1)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Git::Repository constructor path: Git::Repository#worktrees passes self
  # (a Git::Repository) to Git::Worktrees.new
  # ---------------------------------------------------------------------------

  context 'when initialized via Git::Repository (Git::Repository passed to constructor)' do
    let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
    let(:repository) { Git::Repository.new(execution_context: execution_context) }
    let(:worktrees) { repository.worktrees }

    describe '#size' do
      it 'returns 1 for a repository with only the main worktree' do
        expect(worktrees.size).to eq(1)
      end
    end

    describe '#each' do
      it 'yields Git::Worktree objects' do
        expect(worktrees.to_a).to all(be_a(Git::Worktree))
      end

      it 'includes the main worktree directory' do
        expect(worktrees.map(&:dir)).to include(File.realpath(repo_dir))
      end
    end
  end
end
