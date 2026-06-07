# frozen_string_literal: true

require 'spec_helper'

# Integration tests confirming that Git::Base exposes the Git::Repository::Stashing
# facade methods via one-line delegators.

RSpec.describe Git::Base, :integration do
  include_context 'in an empty repository'

  before do
    write_file('file.txt', 'initial content')
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#stashes_all' do
    context 'when there are no stashes' do
      it 'returns an empty array' do
        expect(repo.stashes_all).to eq([])
      end
    end

    context 'after saving a stash' do
      before do
        write_file('file.txt', 'modified')
        repo.stash_save('my work')
      end

      it 'returns a non-empty array' do
        expect(repo.stashes_all).not_to be_empty
      end
    end
  end

  describe '#stash_save' do
    before { write_file('file.txt', 'modified content') }

    it 'returns a truthy value when changes are stashed' do
      result = repo.stash_save('save test')
      expect(result).to be_truthy
    end

    it 'increases the stash count by one' do
      expect { repo.stash_save('work') }.to change { repo.stashes_all.length }.by(1)
    end
  end

  describe '#stash_apply' do
    before do
      write_file('file.txt', 'modified content')
      repo.stash_save('apply test')
    end

    it 'restores stashed changes without raising' do
      expect { repo.stash_apply }.not_to raise_error
    end
  end

  describe '#stash_clear' do
    before do
      write_file('file.txt', 'modified content')
      repo.stash_save('clear test')
    end

    it 'removes all stash entries' do
      repo.stash_clear
      expect(repo.stashes_all).to eq([])
    end
  end
end
