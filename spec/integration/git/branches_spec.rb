# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Branches, :integration do
  include_context 'in an empty repository'

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  # ---------------------------------------------------------------------------
  # Git::Base constructor path: Git::Base#branches passes self (a Git::Base)
  # ---------------------------------------------------------------------------

  describe 'via Git::Base#branches (Git::Base passed to constructor)' do
    let(:branches) { repo.branches }

    it 'returns a Git::Branches instance' do
      expect(branches).to be_a(Git::Branches)
    end

    describe '#local' do
      it 'returns Git::Branch objects' do
        expect(branches.local).to all(be_a(Git::Branch))
      end

      it 'includes the current local branch' do
        expect(branches.local.map(&:full)).to include('main')
      end

      context 'with multiple local branches' do
        before { repo.branch('feature').create }

        it 'includes all local branches' do
          expect(branches.local.map(&:full)).to include('main', 'feature')
        end
      end
    end

    describe '#remote' do
      context 'with no remotes configured' do
        it 'returns an empty collection' do
          expect(branches.remote).to be_empty
        end
      end

      context 'with a remote-tracking branch' do
        let(:bare_dir) { Dir.mktmpdir('bare_repo') }

        after { FileUtils.rm_rf(bare_dir) }

        before do
          Git.init(bare_dir, bare: true)
          repo.add_remote('origin', bare_dir)
          repo.push('origin', 'main')
        end

        it 'returns Git::Branch objects for remote-tracking branches' do
          expect(branches.remote).to all(be_a(Git::Branch))
        end

        it 'includes the remote-tracking branch for origin/main' do
          expect(branches.remote.map(&:full)).to include('remotes/origin/main')
        end
      end
    end

    describe '#size' do
      it 'returns 1 after an initial commit with one branch' do
        expect(branches.size).to eq(1)
      end
    end

    describe '#each' do
      it 'yields Git::Branch objects for every branch' do
        yielded = branches.map { |b| b }
        expect(yielded).to all(be_a(Git::Branch))
        expect(yielded.map(&:full)).to include('main')
      end
    end

    describe '#[]' do
      it 'finds a local branch by its short name' do
        result = branches['main']
        expect(result).to be_a(Git::Branch)
        expect(result.full).to eq('main')
      end

      it 'returns nil for an unknown branch name' do
        expect(branches['nonexistent']).to be_nil
      end

      context 'with a remote-tracking branch' do
        let(:bare_dir) { Dir.mktmpdir('bare_repo') }

        after { FileUtils.rm_rf(bare_dir) }

        before do
          Git.init(bare_dir, bare: true)
          repo.add_remote('origin', bare_dir)
          repo.push('origin', 'main')
        end

        it 'finds a remote-tracking branch by its full refname' do
          result = branches['remotes/origin/main']
          expect(result).to be_a(Git::Branch)
          expect(result.full).to eq('remotes/origin/main')
        end

        it 'finds a remote-tracking branch by its short form (omitting "remotes/")' do
          result = branches['origin/main']
          expect(result).to be_a(Git::Branch)
          expect(result.full).to eq('remotes/origin/main')
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Git::Repository constructor path: Git::Repository#branches passes self
  # (a Git::Repository) to Git::Branches.new
  # ---------------------------------------------------------------------------

  describe 'via Git::Repository#branches (Git::Repository passed to constructor)' do
    let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
    let(:repository) { Git::Repository.new(execution_context: execution_context) }
    let(:branches) { repository.branches }

    it 'returns a Git::Branches instance' do
      expect(branches).to be_a(Git::Branches)
    end

    it 'includes the current local branch' do
      expect(branches.local.map(&:full)).to include('main')
    end

    it 'returns the same number of branches as the Git::Base path' do
      expect(branches.size).to eq(repo.branches.size)
    end
  end
end
