# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/stashing'
require 'git/execution_context/repository'

RSpec.describe Git::Repository::Stashing, :integration do
  include_context 'in an empty repository'

  let(:facade_execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: facade_execution_context) }

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
        repo.lib.stash_save('my feature work')
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
        repo.lib.stash_save('first change')

        write_file('file.txt', 'change for stash 2')
        repo.lib.stash_save('second change')
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
        repo.lib.stash_save('saving: work')
      end

      it 'strips only the branch prefix and keeps the rest of the message' do
        result = described_instance.stashes_all
        # Git stores: "On main: saving: work"; facade strips "On main:" → "saving: work"
        expect(result.first.last).to eq('saving: work')
      end
    end
  end
end
