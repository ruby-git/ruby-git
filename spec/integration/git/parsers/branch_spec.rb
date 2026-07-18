# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/branch'

# Integration tests for Git::Parsers::Branch
#
# These tests verify that the parser correctly handles real git output.
# The parser's parsing logic is tested against actual git branch --list output.
#
# IMPORTANT: These tests validate that the FORMAT_STRING produces output
# matching the format assumptions in unit test fixtures.
#
RSpec.describe Git::Parsers::Branch, :integration do
  include_context 'in an empty repository'

  # Helper to run git branch --list with the parser's format and return raw output
  def git_branch_output(*args)
    format_arg = "--format=#{described_class::FORMAT_STRING}"
    repo.execution_context.command_capturing('branch', '--list', format_arg, *args).stdout
  end

  describe '.parse_list' do
    context 'with basic branches' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature-branch').create
      end

      it 'parses all branches' do
        output = git_branch_output
        result = described_class.parse_list(output)
        expect(result.map(&:short_name)).to contain_exactly('main', 'feature-branch')
      end

      it 'identifies the current branch' do
        output = git_branch_output
        result = described_class.parse_list(output)
        expect(result.find(&:current).short_name).to eq('main')
      end

      it 'returns BranchInfo objects with all expected attributes' do
        output = git_branch_output
        result = described_class.parse_list(output)
        main_branch = result.find { |b| b.short_name == 'main' }

        expect(main_branch).to respond_to(:refname)
        expect(main_branch).to respond_to(:target_oid)
        expect(main_branch).to respond_to(:current)
        expect(main_branch).to respond_to(:worktree_path)
        expect(main_branch).to respond_to(:symref)
        expect(main_branch).to respond_to(:upstream)

        expect(main_branch.current).to be true
        expect(main_branch.worktree_path).to be_nil
        expect(main_branch.symref).to be_nil
        expect(main_branch.target_oid).to match(/\A[0-9a-f]{40}\z/)
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
        output = git_branch_output
        result = described_class.parse_list(output)
        expect(result.map(&:short_name)).to include('feature/with-slash')
      end

      it 'parses branch names with unicode' do
        output = git_branch_output
        result = described_class.parse_list(output)
        expect(result.map(&:short_name)).to include('feature/日本語')
      end
    end

    context 'with upstream tracking' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after do
        FileUtils.rm_rf(bare_dir)
      end

      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')

        Git.init(bare_dir, bare: true)
        repo.remote_add('origin', bare_dir)
        repo.push('origin', 'main')
        repo.execution_context.command_capturing('branch', '-u', 'origin/main', 'main')
      end

      it 'populates upstream as the raw upstream refname string' do
        output = git_branch_output
        result = described_class.parse_list(output)
        main_branch = result.find { |b| b.short_name == 'main' }

        expect(main_branch.upstream).to eq('refs/remotes/origin/main')
      end
    end

    context 'with a slash-containing remote name' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after do
        FileUtils.rm_rf(bare_dir)
      end

      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')

        Git.init(bare_dir, bare: true)
        repo.remote_add('team/upstream', bare_dir)
        repo.push('team/upstream', 'main')
        repo.fetch('team/upstream')
      end

      it 'resolves the remote name using configured remote names' do
        output = git_branch_output('--remotes')
        result = described_class.parse_list(output, remote_names: ['team/upstream'])
        remote_branch = result.find { |branch| branch.refname == 'refs/remotes/team/upstream/main' }

        expect(remote_branch.remote_name).to eq('team/upstream')
        expect(remote_branch.short_name).to eq('main')
      end
    end

    context 'with detached HEAD' do
      before do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.tag_add('v1.0.0')
        write_file('file2.txt')
        repo.add('file2.txt')
        repo.commit('Second commit')
        repo.checkout('v1.0.0')
      end

      it 'filters out detached HEAD entry and only returns real branches' do
        output = git_branch_output
        result = described_class.parse_list(output)

        expect(result.size).to eq(1)
        expect(result.first.short_name).to eq('main')
        expect(result.none? { |b| b.refname.include?('detached') }).to be true
      end
    end
  end
end
