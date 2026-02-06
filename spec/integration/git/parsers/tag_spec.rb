# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/tag'

# Integration tests for Git::Parsers::Tag
#
# These tests verify that the parser correctly handles real git output.
# The parser's parsing logic is tested against actual git tag --list output.
#
RSpec.describe Git::Parsers::Tag, :integration do
  include_context 'in an empty repository'

  # Helper to run git tag --list with the parser's format and return raw output
  def git_tag_output(*args)
    format_arg = "--format=#{described_class::FORMAT_STRING}"
    repo.lib.command('tag', '--list', format_arg, *args).stdout
  end

  describe '.parse_list' do
    context 'when there are no tags' do
      it 'returns an empty array' do
        result = described_class.parse_list('')
        expect(result).to eq([])
      end
    end

    context 'with lightweight tags' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
      end

      it 'returns tag with populated metadata' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.size).to eq(1)
        tag = result.first
        expect(tag.name).to eq('v1.0.0')
        expect(tag.target_oid).to match(/^[0-9a-f]{40}$/)
        expect(tag.objecttype).to eq('commit')
      end

      it 'identifies lightweight tags correctly' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.first.lightweight?).to be true
        expect(result.first.annotated?).to be false
      end

      it 'has nil oid and tagger fields for lightweight tags' do
        output = git_tag_output
        result = described_class.parse_list(output)
        tag = result.first
        expect(tag.oid).to be_nil
        expect(tag.tagger_name).to be_nil
        expect(tag.tagger_email).to be_nil
        expect(tag.tagger_date).to be_nil
        expect(tag.message).to be_nil
      end

      it 'has target_oid pointing to the commit' do
        output = git_tag_output
        result = described_class.parse_list(output)
        tag = result.first
        expect(tag.target_oid).to match(/^[0-9a-f]{40}$/)
      end
    end

    context 'with annotated tags' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v2.0.0', annotate: true, message: 'Release version 2.0.0')
      end

      it 'returns tag with populated metadata' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.size).to eq(1)
        tag = result.first
        expect(tag.name).to eq('v2.0.0')
        expect(tag.oid).to match(/^[0-9a-f]{40}$/)
        expect(tag.target_oid).to match(/^[0-9a-f]{40}$/)
        expect(tag.objecttype).to eq('tag')
      end

      it 'identifies annotated tags correctly' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.first.annotated?).to be true
        expect(result.first.lightweight?).to be false
      end

      it 'has tagger fields populated for annotated tags' do
        output = git_tag_output
        result = described_class.parse_list(output)
        tag = result.first
        expect(tag.tagger_name).not_to be_nil
        expect(tag.tagger_email).not_to be_nil
        expect(tag.tagger_date).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([-+]\d{2}:\d{2}|Z)$/)
        expect(tag.message).to eq('Release version 2.0.0')
      end
    end

    context 'with multi-line tag messages' do
      let(:multiline_message) { "Release v1.0.0\n\nThis release includes:\n- Feature A\n- Bug fix B" }

      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0', annotate: true, message: multiline_message)
        repo.add_tag('v1.1.0', annotate: true, message: 'Simple message')
      end

      it 'captures full multi-line message' do
        output = git_tag_output
        result = described_class.parse_list(output)
        v1_tag = result.find { |t| t.name == 'v1.0.0' }
        expect(v1_tag.message).to eq(multiline_message)
      end

      it 'preserves newlines in message' do
        output = git_tag_output
        result = described_class.parse_list(output)
        v1_tag = result.find { |t| t.name == 'v1.0.0' }
        expect(v1_tag.message).to include("\n")
        expect(v1_tag.message.lines.count).to eq(5)
      end

      it 'does not affect parsing of other tags' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.size).to eq(2)
        v1_1_tag = result.find { |t| t.name == 'v1.1.0' }
        expect(v1_1_tag.message).to eq('Simple message')
      end
    end

    context 'with multiple tags' do
      before do
        write_file('file1.txt', 'content1')
        repo.add('file1.txt')
        repo.commit('First commit')
        repo.add_tag('v1.0.0')

        write_file('file2.txt', 'content2')
        repo.add('file2.txt')
        repo.commit('Second commit')
        repo.add_tag('v1.1.0', annotate: true, message: 'Version 1.1.0')

        write_file('file3.txt', 'content3')
        repo.add('file3.txt')
        repo.commit('Third commit')
        repo.add_tag('v2.0.0')
      end

      it 'returns all tags' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.size).to eq(3)
        expect(result.map(&:name)).to contain_exactly('v1.0.0', 'v1.1.0', 'v2.0.0')
      end

      it 'correctly identifies tag types' do
        output = git_tag_output
        result = described_class.parse_list(output)
        v1_tag = result.find { |t| t.name == 'v1.0.0' }
        v1_1_tag = result.find { |t| t.name == 'v1.1.0' }
        v2_tag = result.find { |t| t.name == 'v2.0.0' }

        expect(v1_tag.lightweight?).to be true
        expect(v1_1_tag.annotated?).to be true
        expect(v2_tag.lightweight?).to be true
      end
    end

    context 'with special characters in tag names' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('release/v1.0')
        repo.add_tag('feature-branch-tag')
      end

      it 'handles tags with slashes' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.map(&:name)).to include('release/v1.0')
      end

      it 'handles tags with hyphens' do
        output = git_tag_output
        result = described_class.parse_list(output)
        expect(result.map(&:name)).to include('feature-branch-tag')
      end
    end
  end

  describe '.parse_deleted_tags' do
    it 'parses deleted tag output' do
      stdout = "Deleted tag 'v1.0.0' (was abc1234)\nDeleted tag 'v2.0.0' (was def5678)\n"
      result = described_class.parse_deleted_tags(stdout)
      expect(result).to contain_exactly('v1.0.0', 'v2.0.0')
    end
  end

  describe 'FORMAT_STRING validation' do
    # These tests validate that real git output matches the format assumptions
    # used in unit test fixtures

    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
      repo.add_tag('v1.0.0', annotate: true, message: 'Release v1.0.0')
    end

    it 'uses unit separator (0x1F) as field delimiter' do
      output = git_tag_output
      expect(output).to include(described_class::FIELD_DELIMITER)
    end

    it 'uses record separator (0x1E) as record delimiter' do
      output = git_tag_output
      expect(output).to include(described_class::RECORD_DELIMITER)
    end

    it 'produces exactly 8 fields per record' do
      output = git_tag_output
      records = output.split(described_class::RECORD_DELIMITER).reject(&:empty?)
      records.each do |record|
        fields = record.split(described_class::FIELD_DELIMITER, -1)
        expect(fields.size).to eq(described_class::FIELD_COUNT),
                               "Expected #{described_class::FIELD_COUNT} fields but got #{fields.size}"
      end
    end

    # rubocop:disable Layout/LineLength
    it 'produces field order: refname, objectname, *objectname, objecttype, taggername, taggeremail, taggerdate, contents' do
      # rubocop:enable Layout/LineLength
      output = git_tag_output
      records = output.split(described_class::RECORD_DELIMITER).reject(&:empty?)
      record = records.first
      fields = record.split(described_class::FIELD_DELIMITER, -1)

      # Field 0: refname:short (tag name)
      expect(fields[0]).to eq('v1.0.0')
      # Field 1: objectname (SHA of tag object)
      expect(fields[1]).to match(/^[0-9a-f]{40}$/)
      # Field 2: *objectname (dereferenced SHA - commit ID)
      expect(fields[2]).to match(/^[0-9a-f]{40}$/)
      # Field 3: objecttype ('tag' for annotated)
      expect(fields[3]).to eq('tag')
      # Field 4: taggername
      expect(fields[4]).to be_a(String)
      # Field 5: taggeremail
      expect(fields[5]).to match(/<.*>/) # e.g., <user@example.com>
      # Field 6: taggerdate (ISO 8601)
      expect(fields[6]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      # Field 7: contents (message)
      expect(fields[7]).to include('Release v1.0.0')
    end
  end
end
