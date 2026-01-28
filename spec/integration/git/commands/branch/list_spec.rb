# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

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

      it 'loads all branches' do
        result = command.call
        expect(result.map(&:refname)).to contain_exactly('main', 'feature-branch')
      end

      it 'identifies the current branch' do
        result = command.call
        expect(result.find(&:current).refname).to eq('main')
      end

      it 'returns BranchInfo objects with all expected attributes' do
        result = command.call
        main_branch = result.find { |b| b.refname == 'main' }

        # Verify all BranchInfo attributes are present
        expect(main_branch).to respond_to(:refname)
        expect(main_branch).to respond_to(:target_oid)
        expect(main_branch).to respond_to(:current)
        expect(main_branch).to respond_to(:worktree)
        expect(main_branch).to respond_to(:symref)
        expect(main_branch).to respond_to(:upstream)

        # Verify current values
        expect(main_branch.current).to be true
        expect(main_branch.worktree).to be false
        expect(main_branch.symref).to be_nil

        # target_oid is populated from format output
        expect(main_branch.target_oid).to match(/\A[0-9a-f]{40}\z/)

        # upstream is nil because no upstream is configured in this test
        expect(main_branch.upstream).to be_nil
      end
    end

    context 'with branch names containing special characters' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature/with-slash').create
        repo.branch('feature/日本語').create
      end

      it 'parses branch names with slashes' do
        result = command.call
        expect(result.map(&:refname)).to include('feature/with-slash')
      end

      it 'parses branch names with unicode' do
        result = command.call
        expect(result.map(&:refname)).to include('feature/日本語')
      end
    end

    context 'with upstream tracking' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after do
        FileUtils.rm_rf(bare_dir)
      end

      before do
        # Create initial content in the test repo
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create a bare repo and add as remote
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')

        # Set upstream tracking
        repo.lib.command('branch', '-u', 'origin/main', 'main')
      end

      it 'populates upstream as BranchInfo with refname' do
        result = command.call
        main_branch = result.find { |b| b.refname == 'main' }

        expect(main_branch.upstream).to be_a(Git::BranchInfo)
        expect(main_branch.upstream.refname).to eq('remotes/origin/main')
        expect(main_branch.upstream.target_oid).to be_nil # Upstream OID not available from format
        expect(main_branch.upstream.current).to be false
        expect(main_branch.upstream.worktree).to be false
      end
    end

    context 'with detached HEAD' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
        write_file('file2.txt')
        repo.add('file2.txt')
        repo.commit('Second commit')

        # Detach HEAD by checking out the tag
        repo.checkout('v1.0.0')
      end

      it 'filters out detached HEAD entry and only returns real branches' do
        result = command.call

        # Should only have the main branch, not the detached HEAD
        expect(result.size).to eq(1)
        expect(result.first.refname).to eq('main')
        expect(result.none? { |b| b.refname.include?('detached') }).to be true
      end
    end
  end
end
