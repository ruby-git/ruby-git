# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/stashing'
RSpec.describe Git::Repository::Stashing, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('file.txt', 'initial content')
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#stashes_all' do
    context 'when there are no stash entries' do
      it 'returns an empty array' do
        expect(described_instance.stashes_all).to eq([])
      end
    end

    context 'when there is one stash entry with a branch prefix' do
      before do
        write_file('file.txt', 'modified content')
        repo.stash_save('my feature work')
      end

      it 'returns a single-element array with index 0' do
        result = described_instance.stashes_all
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(0)
      end

      it 'strips the branch prefix from the message' do
        result = described_instance.stashes_all
        # Git prefixes the message: "On main: my feature work"
        # The facade strips the "On main:" prefix
        expect(result.first.last).to eq('my feature work')
      end
    end

    context 'when there are multiple stash entries' do
      before do
        write_file('file.txt', 'change for stash 1')
        repo.stash_save('first change')

        write_file('file.txt', 'change for stash 2')
        repo.stash_save('second change')
      end

      it 'returns entries in oldest-first order' do
        result = described_instance.stashes_all

        expect(result.length).to eq(2)
        expect(result.map(&:first)).to eq([0, 1])
        expect(result.map(&:last)).to eq(['first change', 'second change'])
      end
    end

    context 'when a stash message contains a colon (e.g. "saving: work")' do
      before do
        write_file('file.txt', 'modified content')
        repo.stash_save('saving: work')
      end

      it 'strips only the branch prefix and keeps the rest of the message' do
        result = described_instance.stashes_all
        # Git stores: "On main: saving: work"; facade strips "On main:" => "saving: work"
        expect(result.first.last).to eq('saving: work')
      end
    end

    context 'when the stash was created from a detached HEAD' do
      before do
        sha = repo.log(1).execute.first.sha
        repo.checkout(sha)
        write_file('file.txt', 'detached change')
        repo.stash_save('detached stash')
      end

      it 'returns the stash message without a branch prefix' do
        result = described_instance.stashes_all
        # Git stores detached-HEAD stashes without an "On <branch>:" prefix
        expect(result.first).to eq([0, 'detached stash'])
      end
    end
  end

  describe '#stash_list' do
    before do
      write_file('file.txt', 'modified content')
      repo.add('file.txt')
      described_instance.stash_save('WIP')
    end

    it 'emits a deprecation warning' do
      expect(Git::Deprecation).to receive(:warn).with(a_string_including('stash_list'))
      described_instance.stash_list
    end

    it 'returns a String' do
      allow(Git::Deprecation).to receive(:warn)
      expect(described_instance.stash_list).to be_a(String)
    end

    it 'contains "stash@{0}"' do
      allow(Git::Deprecation).to receive(:warn)
      expect(described_instance.stash_list).to include('stash@{0}')
    end

    it 'contains the stash message' do
      allow(Git::Deprecation).to receive(:warn)
      expect(described_instance.stash_list).to include('WIP')
    end
  end

  describe '#stash_save' do
    context 'when the repository has no commits (unborn branch)' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) { init_test_repo(unborn_repo_dir) }
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_repo.execution_context) }

      before do
        File.write(File.join(unborn_repo_dir, 'file.txt'), 'hello')
        unborn_repo.add('file.txt')
      end

      after { FileUtils.rm_rf(unborn_repo_dir) }

      it 'raises Git::FailedError' do
        expect { unborn_instance.stash_save('unborn stash') }.to raise_error(Git::FailedError, /stash/)
      end
    end
  end

  describe '#stash_apply' do
    context 'after saving a stash and resetting the working tree' do
      before do
        write_file('file.txt', 'modified content')
        repo.add('file.txt')
        described_instance.stash_save('testing')
        repo.reset
      end

      it 'restores the stashed changes to the working tree' do
        described_instance.stash_apply

        expect(repo.status.changed.keys).to include('file.txt')
      end
    end
  end
end
