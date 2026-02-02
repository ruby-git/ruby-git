# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/set_upstream'

RSpec.describe Git::Commands::Branch::SetUpstream, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }

  after do
    FileUtils.rm_rf(bare_dir)
  end

  describe '#call' do
    context 'when setting upstream for the current branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create a bare repo and add as remote
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
      end

      it 'returns a BranchInfo' do
        result = command.call(set_upstream_to: 'origin/main')

        expect(result).to be_a(Git::BranchInfo)
      end

      it 'sets the upstream for the current branch' do
        result = command.call(set_upstream_to: 'origin/main')

        expect(result.upstream).to be_a(Git::BranchInfo)
        expect(result.upstream.remote_name).to eq('origin')
        expect(result.upstream.short_name).to eq('main')
      end

      it 'returns info for the current branch' do
        result = command.call(set_upstream_to: 'origin/main')

        expect(result.refname).to eq('main')
        expect(result.current?).to be true
      end
    end

    context 'when setting upstream for a specific branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create

        # Create a bare repo and add as remote
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
        repo.push('origin', 'feature')
      end

      it 'sets the upstream for the specified branch' do
        result = command.call('feature', set_upstream_to: 'origin/feature')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature')
        expect(result.upstream).to be_a(Git::BranchInfo)
        expect(result.upstream.remote_name).to eq('origin')
        expect(result.upstream.short_name).to eq('feature')
      end

      it 'does not change the current branch' do
        command.call('feature', set_upstream_to: 'origin/feature')

        expect(repo.current_branch).to eq('main')
      end
    end

    context 'when setting upstream to a different remote branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create

        # Create a bare repo and add as remote
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
        repo.push('origin', 'feature')
      end

      it 'can track a different upstream than the branch name' do
        result = command.call('feature', set_upstream_to: 'origin/main')

        expect(result.upstream).to be_a(Git::BranchInfo)
        expect(result.upstream.remote_name).to eq('origin')
        expect(result.upstream.short_name).to eq('main')
      end
    end

    context 'when the upstream does not exist' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Add remote but don't push
        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
      end

      it 'raises an error' do
        expect { command.call(set_upstream_to: 'origin/nonexistent') }.to raise_error(Git::FailedError)
      end
    end

    context 'when the branch does not exist' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        Git.init(bare_dir, bare: true)
        repo.add_remote('origin', bare_dir)
        repo.push('origin', 'main')
      end

      it 'raises an error' do
        expect { command.call('nonexistent', set_upstream_to: 'origin/main') }.to raise_error(Git::FailedError)
      end
    end
  end
end
