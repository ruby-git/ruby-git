# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/unset_upstream'

RSpec.describe Git::Commands::Branch::UnsetUpstream, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }

  after do
    FileUtils.rm_rf(bare_dir)
  end

  describe '#call' do
    context 'when unsetting upstream for the current branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create a bare repo and add as remote with tracking
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
        execution_context.command('branch', '--set-upstream-to=origin/main', 'main')
      end

      it 'returns a BranchInfo' do
        result = command.call

        expect(result).to be_a(Git::BranchInfo)
      end

      it 'removes the upstream from the current branch' do
        result = command.call

        expect(result.upstream).to be_nil
      end

      it 'returns info for the current branch' do
        result = command.call

        expect(result.refname).to eq('main')
        expect(result.current?).to be true
      end
    end

    context 'when unsetting upstream for a specific branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create

        # Create a bare repo and add as remote with tracking
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
        repo.push('origin', 'feature')
        execution_context.command('branch', '--set-upstream-to=origin/feature', 'feature')
      end

      it 'removes the upstream for the specified branch' do
        result = command.call('feature')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature')
        expect(result.upstream).to be_nil
      end

      it 'does not change the current branch' do
        command.call('feature')

        expect(repo.current_branch).to eq('main')
      end
    end

    context 'when the branch has no upstream' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'raises an error' do
        expect { command.call }.to raise_error(Git::FailedError)
      end
    end

    context 'when the branch does not exist' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'raises an error' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError)
      end
    end
  end
end
