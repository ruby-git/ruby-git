# frozen_string_literal: true

require 'spec_helper'
require 'git/stash_info'

RSpec.describe Git::StashInfo do
  # Default attributes for creating test StashInfo objects
  let(:default_attrs) do
    {
      index: 0,
      name: 'stash@{0}',
      sha: 'abc1234567890abcdef1234567890abcdef123456',
      short_sha: 'abc1234',
      branch: 'main',
      message: 'WIP on main: abc123 Initial commit',
      author_name: 'Test Author',
      author_email: 'author@test.com',
      author_date: '2026-01-24T10:00:00-08:00',
      committer_name: 'Test Committer',
      committer_email: 'committer@test.com',
      committer_date: '2026-01-24T10:00:00-08:00'
    }
  end

  describe '.new' do
    it 'creates a stash info with all attributes' do
      info = described_class.new(**default_attrs)

      expect(info.index).to eq(0)
      expect(info.name).to eq('stash@{0}')
      expect(info.sha).to eq('abc1234567890abcdef1234567890abcdef123456')
      expect(info.short_sha).to eq('abc1234')
      expect(info.branch).to eq('main')
      expect(info.message).to eq('WIP on main: abc123 Initial commit')
      expect(info.author_name).to eq('Test Author')
      expect(info.author_email).to eq('author@test.com')
      expect(info.author_date).to eq('2026-01-24T10:00:00-08:00')
      expect(info.committer_name).to eq('Test Committer')
      expect(info.committer_email).to eq('committer@test.com')
      expect(info.committer_date).to eq('2026-01-24T10:00:00-08:00')
    end
  end

  describe '#to_s' do
    it 'returns the stash name' do
      info = described_class.new(**default_attrs, index: 1,
                                                  name: 'stash@{1}',
                                                  branch: 'feature',
                                                  message: 'WIP on feature: def456 Add feature')

      expect(info.to_s).to eq('stash@{1}')
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      info = described_class.new(**default_attrs)

      expect(info).to be_frozen
    end
  end

  describe 'equality' do
    it 'considers two stash infos with same attributes equal' do
      info1 = described_class.new(**default_attrs)
      info2 = described_class.new(**default_attrs)

      expect(info1).to eq(info2)
    end

    it 'considers two stash infos with different attributes not equal' do
      info1 = described_class.new(**default_attrs)
      info2 = described_class.new(**default_attrs, index: 1, name: 'stash@{1}')

      expect(info1).not_to eq(info2)
    end
  end

  describe '#deconstruct (Data.define default)' do
    subject(:info) { described_class.new(**default_attrs) }

    it 'returns all attributes for pattern matching' do
      # Data.define provides #deconstruct that returns all attribute values
      values = info.deconstruct
      expect(values.length).to eq(12)
      expect(values[0]).to eq(0) # index
      expect(values[1]).to eq('stash@{0}') # name
      expect(values[5]).to eq('WIP on main: abc123 Initial commit') # message
    end

    it 'supports Ruby pattern matching with all attributes' do
      case info
      in [idx, name, sha, short_sha, branch, message, *rest]
        expect(idx).to eq(0)
        expect(name).to eq('stash@{0}')
        expect(sha).to eq('abc1234567890abcdef1234567890abcdef123456')
        expect(short_sha).to eq('abc1234')
        expect(branch).to eq('main')
        expect(message).to eq('WIP on main: abc123 Initial commit')
        expect(rest.length).to eq(6) # remaining author/committer fields
      end
    end
  end
end
