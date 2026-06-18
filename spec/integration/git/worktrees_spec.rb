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
  # Git::Repository constructor path: Git::Repository#worktrees passes self
  # (a Git::Repository) to Git::Worktrees.new
  # ---------------------------------------------------------------------------

  context 'when initialized via Git::Repository (Git::Repository passed to constructor)' do
    let(:execution_context) { repo.execution_context }
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
