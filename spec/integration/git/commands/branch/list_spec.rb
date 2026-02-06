# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

# Integration tests for Git::Commands::Branch::List
#
# These tests verify the command's execution behavior. Parsing logic is
# tested separately in spec/integration/git/branch_parser_spec.rb.
#
RSpec.describe Git::Commands::Branch::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when there are no branches' do
      it 'returns an empty array' do
        result = command.call
        expect(result).to eq([])
      end
    end

    context 'when there are branches' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature-branch').create
      end

      it 'loads all branches as BranchInfo objects' do
        result = command.call
        expect(result).to all(be_a(Git::BranchInfo))
        expect(result.map(&:refname)).to contain_exactly('main', 'feature-branch')
      end
    end

    context 'with :all option' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after { FileUtils.rm_rf(bare_dir) }

      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')

        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
        repo.fetch('origin')
      end

      it 'includes both local and remote branches' do
        result = command.call(all: true)
        refnames = result.map(&:refname)
        expect(refnames).to include('main')
        expect(refnames).to include('remotes/origin/main')
      end
    end

    context 'with :remotes option' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after { FileUtils.rm_rf(bare_dir) }

      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')

        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
        repo.fetch('origin')
      end

      it 'lists only remote branches' do
        result = command.call(remotes: true)
        expect(result.map(&:refname)).to all(include('origin/'))
      end
    end

    context 'with :sort option' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('alpha').create
        repo.branch('beta').create
      end

      it 'returns branches in sorted order' do
        result = command.call(sort: 'refname')
        expect(result.map(&:refname)).to eq(%w[alpha beta main])
      end
    end

    context 'with :contains option' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create
        # Add a new commit only to main (feature doesn't have this)
        write_file('main-only.txt')
        repo.add('main-only.txt')
        repo.commit('Main only commit')
      end

      it 'filters branches containing the commit' do
        head_sha = repo.lib.command('rev-parse', 'HEAD').stdout.strip
        result = command.call(contains: head_sha)
        expect(result.map(&:refname)).to contain_exactly('main')
      end
    end
  end
end
