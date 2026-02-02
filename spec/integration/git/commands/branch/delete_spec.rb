# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/delete'
require 'git/branch_delete_result'
require 'git/branch_delete_failure'

RSpec.describe Git::Commands::Branch::Delete, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when deleting a single merged branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create
      end

      it 'returns a BranchDeleteResult' do
        result = command.call('feature')

        expect(result).to be_a(Git::BranchDeleteResult)
      end

      it 'reports success' do
        result = command.call('feature')

        expect(result.success?).to be true
      end

      it 'includes the deleted branch info' do
        result = command.call('feature')

        expect(result.deleted.size).to eq(1)
        expect(result.deleted.first.short_name).to eq('feature')
      end

      it 'has no failures' do
        result = command.call('feature')

        expect(result.not_deleted).to be_empty
      end

      it 'removes the branch from the repository' do
        command.call('feature')

        branch_list = repo.branches.local.map(&:name)
        expect(branch_list).not_to include('feature')
      end
    end

    context 'when deleting multiple branches' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature1').create
        repo.branch('feature2').create
        repo.branch('feature3').create
      end

      it 'deletes all specified branches' do
        result = command.call('feature1', 'feature2', 'feature3')

        expect(result.success?).to be true
        expect(result.deleted.map(&:short_name)).to contain_exactly('feature1', 'feature2', 'feature3')
      end

      it 'removes all branches from the repository' do
        command.call('feature1', 'feature2', 'feature3')

        branch_list = repo.branches.local.map(&:name)
        expect(branch_list).not_to include('feature1', 'feature2', 'feature3')
      end
    end

    context 'when deleting a nonexistent branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'reports failure' do
        result = command.call('nonexistent')

        expect(result.success?).to be false
      end

      it 'includes the failure reason' do
        result = command.call('nonexistent')

        expect(result.not_deleted.size).to eq(1)
        expect(result.not_deleted.first.name).to eq('nonexistent')
        expect(result.not_deleted.first.error_message).to include('not found')
      end
    end

    context 'when deleting with partial failure' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('exists').create
      end

      it 'deletes existing branches and reports failures' do
        result = command.call('exists', 'nonexistent')

        expect(result.success?).to be false
        expect(result.deleted.map(&:short_name)).to eq(['exists'])
        expect(result.not_deleted.map(&:name)).to eq(['nonexistent'])
      end
    end

    context 'when deleting an unmerged branch without force' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('unmerged').checkout
        write_file('unmerged.txt', 'unmerged content')
        repo.add('unmerged.txt')
        repo.commit('Unmerged commit')
        repo.checkout('main')
      end

      it 'reports failure for unmerged branch' do
        result = command.call('unmerged')

        expect(result.success?).to be false
        expect(result.not_deleted.first.name).to eq('unmerged')
        # Git may use different wording depending on version
        expect(result.not_deleted.first.error_message).to match(/not fully merged|could not be deleted/)
      end
    end

    context 'when using force option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('unmerged').checkout
        write_file('unmerged.txt', 'unmerged content')
        repo.add('unmerged.txt')
        repo.commit('Unmerged commit')
        repo.checkout('main')
      end

      it 'deletes an unmerged branch with force' do
        result = command.call('unmerged', force: true)

        expect(result.success?).to be true
        expect(result.deleted.first.short_name).to eq('unmerged')
      end
    end

    context 'with branch names containing special characters' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature/to-delete').create
      end

      it 'deletes a branch with slashes' do
        result = command.call('feature/to-delete')

        expect(result.success?).to be true
        expect(result.deleted.first.short_name).to eq('feature/to-delete')
      end
    end

    context 'when deleting remote-tracking branches' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after do
        FileUtils.rm_rf(bare_dir)
      end

      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create

        # Create a bare repo and push
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
        repo.push('origin', 'feature')

        # Fetch to get remote-tracking branches
        repo.fetch('origin')
      end

      it 'deletes a remote-tracking branch with remotes: true' do
        result = command.call('origin/feature', remotes: true)

        expect(result.success?).to be true
        expect(result.deleted.size).to eq(1)
        expect(result.deleted.first.short_name).to eq('feature')
        expect(result.deleted.first.remote_name).to eq('origin')
      end

      it 'deletes a remote-tracking branch with r: true alias' do
        # Re-push the branch since previous test may have deleted it
        repo.push('origin', 'feature')
        repo.fetch('origin')

        result = command.call('origin/feature', r: true)

        expect(result.success?).to be true
        expect(result.deleted.first.short_name).to eq('feature')
      end

      it 'removes the remote-tracking branch from the repository' do
        # Re-push the branch since previous test may have deleted it
        repo.push('origin', 'feature')
        repo.fetch('origin')

        command.call('origin/feature', remotes: true)

        remote_branches = repo.branches.remote.map(&:name)
        expect(remote_branches).not_to include('origin/feature')
      end

      it 'deletes multiple remote-tracking branches' do
        repo.branch('feature2').create
        repo.push('origin', 'feature2')
        repo.fetch('origin')

        result = command.call('origin/feature', 'origin/feature2', remotes: true)

        expect(result.success?).to be true
        expect(result.deleted.map(&:short_name)).to contain_exactly('feature', 'feature2')
      end

      it 'handles partial failure with remote branches' do
        result = command.call('origin/feature', 'origin/nonexistent', remotes: true)

        expect(result.success?).to be false
        expect(result.deleted.map(&:short_name)).to eq(['feature'])
        expect(result.not_deleted.map(&:name)).to eq(['origin/nonexistent'])
      end
    end
  end
end
