# frozen_string_literal: true

require 'spec_helper'
require 'git/stash_info'

RSpec.describe Git::StashInfo do
  let(:author) do
    Git::AuthorInfo.new(
      name: 'Test Author',
      email: 'author@test.com',
      date: Time.iso8601('2026-01-24T10:00:00-08:00')
    )
  end

  let(:committer) do
    Git::AuthorInfo.new(
      name: 'Test Committer',
      email: 'committer@test.com',
      date: Time.iso8601('2026-01-24T11:00:00-08:00')
    )
  end

  # Default attributes for creating test StashInfo objects
  let(:default_attrs) do
    {
      index: 0,
      name: 'stash@{0}',
      oid: 'abc1234567890abcdef1234567890abcdef123456',
      short_oid: 'abc1234',
      branch: 'main',
      message: 'WIP on main: abc123 Initial commit',
      author: author,
      committer: committer
    }
  end

  describe '#initialize' do
    subject(:info) { described_class.new(**default_attrs) }

    it 'stores all members' do
      expect(info).to have_attributes(**default_attrs)
    end

    it 'exposes the author and committer as Git::AuthorInfo values whose dates are Time' do
      expect(info.author).to be_a(Git::AuthorInfo)
      expect(info.author.date).to be_a(Time)
      expect(info.committer).to be_a(Git::AuthorInfo)
      expect(info.committer.date).to be_a(Time)
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
      expect(values.length).to eq(8)
      expect(values[0]).to eq(0) # index
      expect(values[1]).to eq('stash@{0}') # name
      expect(values[5]).to eq('WIP on main: abc123 Initial commit') # message
      expect(values[6]).to eq(author)
      expect(values[7]).to eq(committer)
    end

    it 'supports Ruby pattern matching with all attributes' do
      case info
      in [idx, name, oid, short_oid, branch, message, *rest]
        expect(idx).to eq(0)
        expect(name).to eq('stash@{0}')
        expect(oid).to eq('abc1234567890abcdef1234567890abcdef123456')
        expect(short_oid).to eq('abc1234')
        expect(branch).to eq('main')
        expect(message).to eq('WIP on main: abc123 Initial commit')
        expect(rest).to eq([author, committer])
      end
    end
  end
end
