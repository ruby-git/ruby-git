# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/stash'

# Integration tests for Git::Parsers::Stash
#
# These tests verify that the parser correctly handles real git output.
# The parser's parsing logic is tested against actual git stash list output.
#
RSpec.describe Git::Parsers::Stash, :integration do
  include_context 'in an empty repository'

  # Helper to run git stash list with the parser's format and return raw output
  def git_stash_output
    format_arg = "--format=#{described_class::STASH_FORMAT}"
    repo.lib.command('stash', 'list', format_arg).stdout
  end

  before do
    write_file('file.txt', 'initial content')
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '.parse_list' do
    context 'with no stashes' do
      it 'returns an empty array' do
        result = described_class.parse_list('')
        expect(result).to eq([])
      end
    end

    context 'with a single stash' do
      before do
        write_file('file.txt', 'modified content')
        repo.lib.stash_save('WIP on feature')
      end

      it 'returns an array with one StashInfo' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.size).to eq(1)
        expect(result.first).to be_a(Git::StashInfo)
      end

      it 'parses the stash index correctly' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.first.index).to eq(0)
      end

      it 'parses the stash name correctly' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.first.name).to eq('stash@{0}')
      end

      it 'parses the OID fields (verifies format string produces valid SHA)' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.first.oid).to match(/\A[0-9a-f]{40}\z/)
        expect(result.first.short_oid).to match(/\A[0-9a-f]{7,}\z/)
      end

      it 'parses the message correctly' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.first.message).to include('WIP on feature')
      end

      it 'parses author information (verifies format string includes author)' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.first.author_name).to be_a(String)
        expect(result.first.author_name).not_to be_empty
        expect(result.first.author_email).to match(/@/)
        expect(result.first.author_date).to be_a(String)
      end

      it 'parses committer information (verifies format string includes committer)' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.first.committer_name).to be_a(String)
        expect(result.first.committer_name).not_to be_empty
        expect(result.first.committer_email).to match(/@/)
        expect(result.first.committer_date).to be_a(String)
      end
    end

    context 'with multiple stashes' do
      before do
        write_file('file.txt', 'first change')
        repo.lib.stash_save('First stash')

        write_file('file.txt', 'second change')
        repo.lib.stash_save('Second stash')

        write_file('file.txt', 'third change')
        repo.lib.stash_save('Third stash')
      end

      it 'returns stashes in order (newest first)' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.size).to eq(3)
        expect(result[0].index).to eq(0)
        expect(result[1].index).to eq(1)
        expect(result[2].index).to eq(2)
      end

      it 'assigns correct names to each stash' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result[0].name).to eq('stash@{0}')
        expect(result[1].name).to eq('stash@{1}')
        expect(result[2].name).to eq('stash@{2}')
      end

      it 'preserves distinct messages for each stash' do
        output = git_stash_output
        result = described_class.parse_list(output)

        messages = result.map(&:message)
        expect(messages[0]).to include('Third stash')
        expect(messages[1]).to include('Second stash')
        expect(messages[2]).to include('First stash')
      end

      it 'assigns unique OIDs to each stash' do
        output = git_stash_output
        result = described_class.parse_list(output)

        oids = result.map(&:oid)
        expect(oids.uniq.size).to eq(3)
      end
    end

    context 'with custom message format (no branch prefix)' do
      before do
        write_file('file.txt', 'modified')
        result = repo.lib.command('stash', 'create', 'Custom message')
        sha = result.is_a?(String) ? result.strip : result.stdout.strip
        repo.lib.command('stash', 'store', '--message=custom: my message', sha)
      end

      it 'parses custom message correctly' do
        output = git_stash_output
        result = described_class.parse_list(output)

        expect(result.first.message).to eq('custom: my message')
        expect(result.first.branch).to be_nil
      end
    end
  end

  describe 'STASH_FORMAT validation' do
    # These tests validate that real git output matches the format assumptions
    # used in unit test fixtures

    before do
      write_file('file.txt', 'modified content')
      repo.lib.stash_save('Test stash message')
    end

    it 'uses unit separator (0x1F) as field separator' do
      output = git_stash_output
      expect(output).to include(described_class::FIELD_SEPARATOR)
    end

    it 'produces exactly 10 fields per line' do
      output = git_stash_output
      output.each_line do |line|
        fields = line.chomp.split(described_class::FIELD_SEPARATOR, -1)
        expect(fields.size).to eq(described_class::FIELD_COUNT),
                               "Expected #{described_class::FIELD_COUNT} fields but got #{fields.size}"
      end
    end

    # rubocop:disable Layout/LineLength
    it 'produces field order: oid, short_oid, reflog, message, author_name, author_email, author_date, committer_name, committer_email, committer_date' do
      # rubocop:enable Layout/LineLength
      output = git_stash_output
      line = output.lines.first.chomp
      fields = line.split(described_class::FIELD_SEPARATOR, -1)

      # Field 0: %H - full SHA (40 hex chars)
      expect(fields[0]).to match(/^[0-9a-f]{40}$/)
      # Field 1: %h - short SHA (7+ hex chars)
      expect(fields[1]).to match(/^[0-9a-f]{7,}$/)
      # Field 2: %gd - reflog selector (stash@{n})
      expect(fields[2]).to match(/^stash@\{\d+\}$/)
      # Field 3: %gs - reflog subject (message)
      expect(fields[3]).to include('Test stash message')
      # Field 4: %an - author name
      expect(fields[4]).to be_a(String)
      expect(fields[4]).not_to be_empty
      # Field 5: %ae - author email
      expect(fields[5]).to match(/@/)
      # Field 6: %aI - author date (ISO 8601)
      expect(fields[6]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      # Field 7: %cn - committer name
      expect(fields[7]).to be_a(String)
      expect(fields[7]).not_to be_empty
      # Field 8: %ce - committer email
      expect(fields[8]).to match(/@/)
      # Field 9: %cI - committer date (ISO 8601)
      expect(fields[9]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end
end
