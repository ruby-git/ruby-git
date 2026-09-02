# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/stash'

RSpec.describe Git::Parsers::Stash do
  let(:field_sep) { "\x1f" }

  describe '.parse_list' do
    it 'parses a single stash entry' do
      line = [
        'abc123def456789012345678901234567890abcdef', # full SHA
        'abc123d',                                     # short SHA
        'stash@{0}',                                   # reflog selector
        'WIP on main: def456 Initial commit', # message
        'Jane Doe',                                    # author name
        'jane@example.com',                            # author email
        '2026-01-24T10:30:00-08:00', # author date
        'Jane Doe',                                    # committer name
        'jane@example.com',                            # committer email
        '2026-01-24T10:30:00-08:00' # committer date
      ].join(field_sep)

      result = described_class.parse_list(line)

      expect(result.size).to eq(1)
      expect(result[0].index).to eq(0)
      expect(result[0].name).to eq('stash@{0}')
      expect(result[0].oid).to eq('abc123def456789012345678901234567890abcdef')
      expect(result[0].short_oid).to eq('abc123d')
      expect(result[0].branch).to eq('main')
      expect(result[0].message).to eq('WIP on main: def456 Initial commit')
      expect(result[0].author).to eq(
        Git::AuthorInfo.new(
          name: 'Jane Doe', email: 'jane@example.com', date: Time.iso8601('2026-01-24T10:30:00-08:00')
        )
      )
      expect(result[0].committer).to eq(
        Git::AuthorInfo.new(
          name: 'Jane Doe', email: 'jane@example.com', date: Time.iso8601('2026-01-24T10:30:00-08:00')
        )
      )
    end

    it 'parses the author and committer dates into Time values that preserve the UTC offset' do
      line = [
        'abc123', 'abc', 'stash@{0}', 'WIP on main: msg',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00-08:00',
        'John', 'john@ex.com', '2026-01-24T19:30:00+01:00'
      ].join(field_sep)

      result = described_class.parse_list(line)

      expect(result[0].author.date).to be_a(Time)
      expect(result[0].author.date.utc_offset).to eq(-8 * 3600)
      expect(result[0].committer.date).to be_a(Time)
      expect(result[0].committer.date.utc_offset).to eq(3600)
    end

    it 'parses multiple stash entries' do
      line1 = [
        'abc123', 'abc', 'stash@{0}', 'WIP on main: msg1',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z'
      ].join(field_sep)

      line2 = [
        'def456', 'def', 'stash@{1}', 'On feature: msg2',
        'John', 'john@ex.com', '2026-01-23T09:00:00Z',
        'John', 'john@ex.com', '2026-01-23T09:00:00Z'
      ].join(field_sep)

      result = described_class.parse_list("#{line1}\n#{line2}")

      expect(result.size).to eq(2)
      expect(result[0].index).to eq(0)
      expect(result[0].branch).to eq('main')
      expect(result[1].index).to eq(1)
      expect(result[1].branch).to eq('feature')
    end

    it 'returns empty array for empty input' do
      result = described_class.parse_list('')

      expect(result).to eq([])
    end

    it 'handles custom stash messages without branch' do
      line = [
        'abc123', 'abc', 'stash@{0}', 'Custom stash message',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z'
      ].join(field_sep)

      result = described_class.parse_list(line)

      expect(result[0].branch).to be_nil
      expect(result[0].message).to eq('Custom stash message')
    end

    it 'raises UnexpectedResultError for malformed lines' do
      malformed_line = "abc123#{field_sep}abc" # Only 2 fields

      expect do
        described_class.parse_list(malformed_line)
      end.to raise_error(Git::UnexpectedResultError, /Expected 10 fields/)
    end

    it 'raises UnexpectedResultError when a date field is not a valid ISO 8601 date' do
      line = [
        'abc123', 'abc', 'stash@{0}', 'WIP on main: msg',
        'Jane', 'jane@ex.com', 'not-a-date',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z'
      ].join(field_sep)

      expect do
        described_class.parse_list(line)
      end.to raise_error(Git::UnexpectedResultError, /not-a-date/)
    end
  end

  describe '.parse_stash_line' do
    it 'parses a valid stash line' do
      line = [
        'abc123', 'abc', 'stash@{0}', 'WIP on main: msg',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z'
      ].join(field_sep)

      result = described_class.parse_stash_line(line, 0, [line])

      expect(result).to be_a(Git::StashInfo)
      expect(result.index).to eq(0)
    end

    it 'raises for invalid line format' do
      expect do
        described_class.parse_stash_line('invalid', 0, ['invalid'])
      end.to raise_error(Git::UnexpectedResultError)
    end
  end

  describe '.build_stash_info' do
    it 'builds StashInfo with extracted index' do
      parts = [
        'abc123', 'abc', 'stash@{5}', 'WIP on main: msg',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z'
      ]

      result = described_class.build_stash_info(parts, 0)

      # Uses index from reflog selector (5), not expected_index (0)
      expect(result.index).to eq(5)
    end

    it 'falls back to expected_index if reflog cannot be parsed' do
      parts = [
        'abc123', 'abc', 'invalid-reflog', 'WIP on main: msg',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z',
        'Jane', 'jane@ex.com', '2026-01-24T10:30:00Z'
      ]

      result = described_class.build_stash_info(parts, 7)

      expect(result.index).to eq(7)
    end
  end

  describe '.stash_info_attrs' do
    it 'builds attributes hash from parts' do
      parts = [
        'fullsha', 'short', 'stash@{3}', 'WIP on feature: msg',
        'Author', 'author@ex.com', '2026-01-24T10:00:00Z',
        'Committer', 'committer@ex.com', '2026-01-24T11:00:00Z'
      ]

      result = described_class.stash_info_attrs(parts, 3)

      expect(result[:index]).to eq(3)
      expect(result[:name]).to eq('stash@{3}')
      expect(result[:oid]).to eq('fullsha')
      expect(result[:short_oid]).to eq('short')
      expect(result[:branch]).to eq('feature')
      expect(result[:message]).to eq('WIP on feature: msg')
      expect(result[:author]).to eq(
        Git::AuthorInfo.new(name: 'Author', email: 'author@ex.com', date: Time.iso8601('2026-01-24T10:00:00Z'))
      )
      expect(result[:committer]).to eq(
        Git::AuthorInfo.new(name: 'Committer', email: 'committer@ex.com', date: Time.iso8601('2026-01-24T11:00:00Z'))
      )
    end
  end

  describe '.extract_index' do
    it 'extracts index from valid reflog selector' do
      expect(described_class.extract_index('stash@{0}')).to eq(0)
      expect(described_class.extract_index('stash@{5}')).to eq(5)
      expect(described_class.extract_index('stash@{123}')).to eq(123)
    end

    it 'returns nil for invalid reflog selector' do
      expect(described_class.extract_index('invalid')).to be_nil
      expect(described_class.extract_index('stash')).to be_nil
      expect(described_class.extract_index('')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(described_class.extract_index(nil)).to be_nil
    end
  end

  describe '.extract_branch' do
    it 'extracts branch from "WIP on <branch>:" format' do
      expect(described_class.extract_branch('WIP on main: abc123 Some commit')).to eq('main')
      expect(described_class.extract_branch('WIP on feature/test: def456 Other')).to eq('feature/test')
    end

    it 'extracts branch from "On <branch>:" format' do
      expect(described_class.extract_branch('On main: abc123 Some commit')).to eq('main')
      expect(described_class.extract_branch('On develop: def456 Other')).to eq('develop')
    end

    it 'returns nil for custom messages' do
      expect(described_class.extract_branch('Custom stash message')).to be_nil
      expect(described_class.extract_branch('My work in progress')).to be_nil
    end

    it 'handles branch names with special characters' do
      expect(described_class.extract_branch('WIP on feature/my-branch: msg')).to eq('feature/my-branch')
      expect(described_class.extract_branch('On release/v1.0.0: msg')).to eq('release/v1.0.0')
    end
  end

  describe '.unexpected_stash_line_error' do
    it 'generates a helpful error message' do
      lines = ['malformed']
      error = described_class.unexpected_stash_line_error(lines, 'malformed', 0)

      expect(error).to include('Unexpected line')
      expect(error).to include('Expected 10 fields')
      expect(error).to include('malformed')
      expect(error).to include('git stash list')
    end
  end

  describe 'edge cases' do
    context 'with field separator in message' do
      it 'documents known limitation with \\x1f in stash message' do
        # This documents a known limitation: if a stash message contains the
        # field separator (\x1f), split() with a limit still keeps exactly 10
        # parts, but the message gets split causing all subsequent fields to
        # shift. The shifted author date field then holds the author email,
        # which is not a valid ISO 8601 date, so parsing fails with the
        # parser's usual error. This is extremely rare in practice since \x1f
        # is a non-printable control character.
        field_sep = described_class::FIELD_SEPARATOR
        line = "abc123#{field_sep}abc#{field_sep}stash@{0}#{field_sep}" \
               "Message with #{field_sep} inside#{field_sep}" \
               "author#{field_sep}email@example.com#{field_sep}2024-01-15T10:00:00Z#{field_sep}" \
               "committer#{field_sep}cemail@example.com#{field_sep}2024-01-15T10:00:00Z"

        expect do
          described_class.parse_stash_line(line, 0, [line])
        end.to raise_error(Git::UnexpectedResultError, /email@example\.com/)
      end
    end
  end
end
