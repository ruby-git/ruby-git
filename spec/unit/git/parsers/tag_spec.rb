# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/tag'

RSpec.describe Git::Parsers::Tag do
  let(:field_sep) { "\x1f" }
  let(:record_sep) { "\x1e" }

  describe '.parse_list' do
    it 'parses a single annotated tag' do
      record = [
        'v1.0.0', # name
        'abc123def456789012345678901234567890abcdef', # objectname (tag object)
        'def456789012345678901234567890abcdef012345', # *objectname (commit)
        'tag',                                        # objecttype
        'John Doe',                                   # tagger name
        '<john@example.com>',                         # tagger email
        '2024-01-15T10:30:00-08:00', # tagger date
        'Release version 1.0.0' # message
      ].join(field_sep) + record_sep

      result = described_class.parse_list(record)

      expect(result.size).to eq(1)
      expect(result[0].name).to eq('v1.0.0')
      expect(result[0].oid).to eq('abc123def456789012345678901234567890abcdef')
      expect(result[0].target_oid).to eq('def456789012345678901234567890abcdef012345')
      expect(result[0].objecttype).to eq('tag')
      expect(result[0].tagger_name).to eq('John Doe')
      expect(result[0].tagger_email).to eq('<john@example.com>')
      expect(result[0].tagger_date).to eq('2024-01-15T10:30:00-08:00')
      expect(result[0].message).to eq('Release version 1.0.0')
      expect(result[0].annotated?).to be true
    end

    it 'parses a lightweight tag' do
      record = [
        'v0.1.0', # name
        'abc123def456789012345678901234567890abcdef', # objectname (commit)
        '',                                          # *objectname (empty for lightweight)
        'commit',                                    # objecttype
        '',                                          # tagger name (empty)
        '',                                          # tagger email (empty)
        '',                                          # tagger date (empty)
        ''                                           # message (empty)
      ].join(field_sep) + record_sep

      result = described_class.parse_list(record)

      expect(result.size).to eq(1)
      expect(result[0].name).to eq('v0.1.0')
      expect(result[0].oid).to be_nil
      expect(result[0].target_oid).to eq('abc123def456789012345678901234567890abcdef')
      expect(result[0].objecttype).to eq('commit')
      expect(result[0].tagger_name).to be_nil
      expect(result[0].tagger_email).to be_nil
      expect(result[0].tagger_date).to be_nil
      expect(result[0].message).to be_nil
      expect(result[0].lightweight?).to be true
    end

    it 'parses multiple tags' do
      records = [
        ['v1.0.0', 'abc123', 'def456', 'tag', 'John', '<john@ex.com>', '2024-01-15T10:30:00Z', 'Msg 1'].join(field_sep),
        ['v0.1.0', 'ghi789', '', 'commit', '', '', '', ''].join(field_sep)
      ].join(record_sep) + record_sep

      result = described_class.parse_list(records)

      expect(result.size).to eq(2)
      expect(result[0].name).to eq('v1.0.0')
      expect(result[1].name).to eq('v0.1.0')
    end

    it 'handles multi-line messages' do
      message = "First line\n\nSecond paragraph\nThird line"
      record = [
        'v2.0.0', 'abc123', 'def456', 'tag', 'John', '<john@ex.com>', '2024-01-15T10:30:00Z', message
      ].join(field_sep) + record_sep

      result = described_class.parse_list(record)

      expect(result[0].message).to eq("First line\n\nSecond paragraph\nThird line")
    end

    it 'returns empty array for empty input' do
      result = described_class.parse_list('')

      expect(result).to be_empty
    end

    it 'handles leading whitespace from previous records' do
      tag_fields = ['v1.0.0', 'abc', 'def', 'tag', 'J', '<j@e.com>', '2024-01-15', 'Msg']
      records = "\n#{tag_fields.join(field_sep)}#{record_sep}"
      result = described_class.parse_list(records)

      expect(result.size).to eq(1)
      expect(result[0].name).to eq('v1.0.0')
    end

    it 'raises UnexpectedResultError for malformed records' do
      malformed_record = "v1.0.0#{field_sep}abc123#{record_sep}" # Only 2 fields

      expect do
        described_class.parse_list(malformed_record)
      end.to raise_error(Git::UnexpectedResultError, /Expected 8 fields/)
    end
  end

  describe '.parse_tag_record' do
    it 'parses annotated tag record' do
      record = ['v1.0.0', 'abc123', 'def456', 'tag', 'John', '<john@ex.com>', '2024-01-15', 'Msg'].join(field_sep)
      result = described_class.parse_tag_record(record, 0, [record])

      expect(result.name).to eq('v1.0.0')
      expect(result.oid).to eq('abc123')
      expect(result.target_oid).to eq('def456')
    end

    it 'parses lightweight tag record' do
      record = ['v0.1.0', 'abc123', '', 'commit', '', '', '', ''].join(field_sep)
      result = described_class.parse_tag_record(record, 0, [record])

      expect(result.name).to eq('v0.1.0')
      expect(result.oid).to be_nil
      expect(result.target_oid).to eq('abc123')
    end
  end

  describe '.build_tag_info' do
    it 'builds TagInfo for annotated tag' do
      parts = ['v1.0.0', 'abc123', 'def456', 'tag', 'John', '<john@ex.com>', '2024-01-15', 'Message']
      result = described_class.build_tag_info(parts)

      expect(result.name).to eq('v1.0.0')
      expect(result.oid).to eq('abc123')
      expect(result.target_oid).to eq('def456')
      expect(result.tagger_name).to eq('John')
    end

    it 'builds TagInfo for lightweight tag' do
      parts = ['v0.1.0', 'abc123', '', 'commit', '', '', '', '']
      result = described_class.build_tag_info(parts)

      expect(result.oid).to be_nil
      expect(result.target_oid).to eq('abc123')
      expect(result.tagger_name).to be_nil
    end
  end

  describe '.parse_optional_field' do
    it 'returns value for non-empty string' do
      expect(described_class.parse_optional_field('John Doe')).to eq('John Doe')
    end

    it 'returns nil for empty string' do
      expect(described_class.parse_optional_field('')).to be_nil
    end
  end

  describe '.parse_message' do
    it 'returns message for annotated tag' do
      expect(described_class.parse_message('tag', 'Release notes')).to eq('Release notes')
    end

    it 'returns nil for lightweight tag' do
      expect(described_class.parse_message('commit', '')).to be_nil
    end

    it 'strips trailing newlines' do
      expect(described_class.parse_message('tag', "Message with newline\n")).to eq('Message with newline')
    end

    it 'returns nil for empty message even on annotated tag' do
      expect(described_class.parse_message('tag', '')).to be_nil
    end
  end

  describe '.parse_deleted_tags' do
    it 'parses single deleted tag' do
      stdout = "Deleted tag 'v1.0.0' (was abc123)\n"
      result = described_class.parse_deleted_tags(stdout)

      expect(result).to eq(['v1.0.0'])
    end

    it 'parses multiple deleted tags' do
      stdout = <<~OUTPUT
        Deleted tag 'v1.0.0' (was abc123)
        Deleted tag 'v2.0.0' (was def456)
      OUTPUT
      result = described_class.parse_deleted_tags(stdout)

      expect(result).to eq(['v1.0.0', 'v2.0.0'])
    end

    it 'returns empty array for empty output' do
      result = described_class.parse_deleted_tags('')

      expect(result).to eq([])
    end

    it 'handles tag names with special characters' do
      stdout = "Deleted tag 'release/v1.0.0-rc.1' (was abc123)\n"
      result = described_class.parse_deleted_tags(stdout)

      expect(result).to eq(['release/v1.0.0-rc.1'])
    end
  end

  describe '.parse_error_messages' do
    it 'parses single error message' do
      stderr = "error: tag 'v1.0.0' not found.\n"
      result = described_class.parse_error_messages(stderr)

      expect(result).to eq({ 'v1.0.0' => "error: tag 'v1.0.0' not found." })
    end

    it 'parses multiple error messages' do
      stderr = <<~OUTPUT
        error: tag 'v1.0.0' not found.
        error: tag 'v2.0.0' not found.
      OUTPUT
      result = described_class.parse_error_messages(stderr)

      expect(result).to eq({
                             'v1.0.0' => "error: tag 'v1.0.0' not found.",
                             'v2.0.0' => "error: tag 'v2.0.0' not found."
                           })
    end

    it 'returns empty hash for empty stderr' do
      result = described_class.parse_error_messages('')

      expect(result).to eq({})
    end

    it 'ignores non-matching lines' do
      stderr = <<~OUTPUT
        Some other output
        error: tag 'missing' not found.
        Another line
      OUTPUT
      result = described_class.parse_error_messages(stderr)

      expect(result).to eq({ 'missing' => "error: tag 'missing' not found." })
    end
  end

  describe '.build_delete_result' do
    let(:tag_info) do
      Git::TagInfo.new(
        name: 'v1.0.0',
        oid: 'abc123',
        target_oid: 'def456',
        objecttype: 'tag',
        tagger_name: 'John',
        tagger_email: '<john@ex.com>',
        tagger_date: '2024-01-15',
        message: 'Release'
      )
    end

    it 'builds result with deleted tags' do
      requested_names = ['v1.0.0']
      existing_tags = { 'v1.0.0' => tag_info }
      deleted_names = ['v1.0.0']
      error_map = {}

      result = described_class.build_delete_result(
        requested_names, existing_tags, deleted_names, error_map
      )

      expect(result).to be_a(Git::TagDeleteResult)
      expect(result.success?).to be true
      expect(result.deleted.size).to eq(1)
      expect(result.deleted[0].name).to eq('v1.0.0')
      expect(result.not_deleted).to be_empty
    end

    it 'builds result with failures' do
      requested_names = ['v1.0.0', 'missing']
      existing_tags = { 'v1.0.0' => tag_info }
      deleted_names = ['v1.0.0']
      error_map = { 'missing' => "error: tag 'missing' not found." }

      result = described_class.build_delete_result(
        requested_names, existing_tags, deleted_names, error_map
      )

      expect(result.success?).to be false
      expect(result.deleted.size).to eq(1)
      expect(result.not_deleted.size).to eq(1)
      expect(result.not_deleted[0].name).to eq('missing')
      expect(result.not_deleted[0].error_message).to eq("error: tag 'missing' not found.")
    end

    it 'uses default error message when not in error_map' do
      requested_names = ['missing']
      existing_tags = {}
      deleted_names = []
      error_map = {}

      result = described_class.build_delete_result(
        requested_names, existing_tags, deleted_names, error_map
      )

      expect(result.not_deleted[0].error_message).to eq("tag 'missing' could not be deleted")
    end
  end

  describe '.unexpected_tag_record_error' do
    it 'generates a helpful error message' do
      records = ['malformed']
      error = described_class.unexpected_tag_record_error(records, 'malformed', 0)

      expect(error).to include('Unexpected record')
      expect(error).to include('Expected 8 fields')
      expect(error).to include('malformed')
    end
  end

  describe 'edge cases' do
    context 'with field delimiter in message' do
      it 'handles \\x1f in tag message correctly (last field)' do
        # Tag messages containing the field delimiter (\x1f) are handled correctly
        # because %(contents) is the last field. The split() limit ensures everything
        # after the 7th delimiter is kept together as the message.
        field_sep = described_class::FIELD_DELIMITER
        record = "v1.0.0#{field_sep}abc123#{field_sep}def456#{field_sep}tag#{field_sep}" \
                 "Tagger#{field_sep}<t@e.com>#{field_sep}2024-01-15T10:00:00+00:00#{field_sep}" \
                 "Message with #{field_sep} inside"

        # This should parse correctly because message is the last field
        result = described_class.parse_tag_record(record, 0, [record])

        expect(result.name).to eq('v1.0.0')
        expect(result.message).to eq("Message with #{field_sep} inside")
      end
    end
  end
end
