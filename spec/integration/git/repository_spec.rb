# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'

# Integration tests for the Git::Repository.open / .bare factory class methods
# and the path accessors (#dir, #repo, #index, #repo_size) they configure.
#
# These exercise real path resolution against real repositories on disk. The
# regression examples confirm that Step C1a-1 remains additive: the top-level
# Git.open and Git.bare entry points still return Git::Base, not Git::Repository.

RSpec.describe Git::Repository, :integration do
  describe '.open' do
    include_context 'in an empty repository'

    subject(:repository) { described_class.open(repo_dir, options) }

    let(:options) { {} }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'exposes the working directory through #dir' do
      expect(repository.dir).to eq(Pathname.new(repo_dir).realpath)
    end

    it 'exposes the repository directory through #repo' do
      expect(repository.repo).to eq(Pathname.new(File.join(repo_dir, '.git')).realpath)
    end

    it 'exposes the index file through #index' do
      expect(repository.index).to eq(repository.repo.join('index'))
    end

    it 'reports a positive repository size through #repo_size' do
      expect(repository.repo_size).to be > 0
    end

    context 'when given an explicit repository path' do
      let(:options) { { repository: File.join(repo_dir, '.git') } }

      it 'uses the given repository directory' do
        expect(repository.repo).to eq(Pathname.new(File.join(repo_dir, '.git')))
      end
    end
  end

  describe '.bare' do
    subject(:repository) { described_class.bare(bare_dir) }

    let(:bare_dir) { Dir.mktmpdir }

    before { Git.init(bare_dir, bare: true) }

    after { FileUtils.rm_rf(bare_dir) }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'has no working directory' do
      expect(repository.dir).to be_nil
    end

    it 'exposes the bare repository directory through #repo' do
      expect(repository.repo).to eq(Pathname.new(bare_dir))
    end

    it 'reports a positive repository size through #repo_size' do
      expect(repository.repo_size).to be > 0
    end
  end

  describe 'top-level entry-point regression' do
    include_context 'in an empty repository'

    it 'Git.open still returns a Git::Base' do
      expect(Git.open(repo_dir)).to be_a(Git::Base)
    end

    it 'Git.bare still returns a Git::Base' do
      bare_dir = Dir.mktmpdir
      Git.init(bare_dir, bare: true)
      expect(Git.bare(bare_dir)).to be_a(Git::Base)
    ensure
      FileUtils.rm_rf(bare_dir)
    end
  end
end
