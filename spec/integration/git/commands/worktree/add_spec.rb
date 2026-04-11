# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'
require 'git/commands/worktree/add'

RSpec.describe Git::Commands::Worktree::Add, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      context 'with a path' do
        let(:worktree_path) { File.join(repo_dir, '..', "worktree-#{SecureRandom.hex(4)}") }

        after { FileUtils.rm_rf(worktree_path) }

        it 'returns a CommandLineResult' do
          result = command.call(worktree_path)
          expect(result).to be_a(Git::CommandLineResult)
        end

        it 'creates the worktree directory on disk' do
          command.call(worktree_path)
          expect(File.directory?(worktree_path)).to be(true)
        end

        it 'creates a .git file in the worktree' do
          command.call(worktree_path)
          expect(File.exist?(File.join(worktree_path, '.git'))).to be(true)
        end
      end

      context 'with --detach' do
        let(:worktree_path) { File.join(repo_dir, '..', "worktree-detach-#{SecureRandom.hex(4)}") }

        after { FileUtils.rm_rf(worktree_path) }

        it 'creates a detached HEAD worktree' do
          result = command.call(worktree_path, detach: true)
          expect(result).to be_a(Git::CommandLineResult)
          expect(File.directory?(worktree_path)).to be(true)
        end
      end

      context 'with --lock and --reason' do
        let(:worktree_path) { File.join(repo_dir, '..', "worktree-locked-#{SecureRandom.hex(4)}") }

        after { FileUtils.rm_rf(worktree_path) }

        it 'creates a locked worktree with the given reason' do
          result = command.call(worktree_path, lock: true, reason: 'on portable device')
          expect(result).to be_a(Git::CommandLineResult)
          expect(File.directory?(worktree_path)).to be(true)
        end
      end

      context 'with --relative-paths' do
        let(:worktree_path) { File.join(repo_dir, '..', "worktree-relative-#{SecureRandom.hex(4)}") }

        after { FileUtils.rm_rf(worktree_path) }

        it 'creates the worktree successfully' do
          result = command.call(worktree_path, relative_paths: true)
          expect(result).to be_a(Git::CommandLineResult)
          expect(File.directory?(worktree_path)).to be(true)
        end
      end

      context 'with --orphan', skip: unless_git('2.41', 'git worktree add --orphan') do
        let(:worktree_path) { File.join(repo_dir, '..', "worktree-orphan-#{SecureRandom.hex(4)}") }

        after { FileUtils.rm_rf(worktree_path) }

        it 'creates a worktree on a new unborn branch' do
          result = command.call(worktree_path, orphan: true)
          expect(result).to be_a(Git::CommandLineResult)
          expect(File.directory?(worktree_path)).to be(true)
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent commit-ish' do
        worktree_path = File.join(repo_dir, '..', "worktree-fail-#{SecureRandom.hex(4)}")
        expect { command.call(worktree_path, 'nonexistent-branch-xyz') }
          .to raise_error(Git::FailedError, /nonexistent-branch-xyz/)
      ensure
        FileUtils.rm_rf(worktree_path)
      end
    end
  end
end
