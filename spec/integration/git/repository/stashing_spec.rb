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
end
