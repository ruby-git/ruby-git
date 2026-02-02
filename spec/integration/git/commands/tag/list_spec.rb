# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/list'

RSpec.describe Git::Commands::Tag::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when there are no tags' do
      it 'returns an empty array' do
        result = command.call
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
        result = command.call
        expect(result.size).to eq(1)
        tag = result.first
        expect(tag.name).to eq('v1.0.0')
        expect(tag.target_oid).to match(/^[0-9a-f]{40}$/)
        expect(tag.objecttype).to eq('commit')
      end

      it 'identifies lightweight tags correctly' do
        result = command.call
        expect(result.first.lightweight?).to be true
        expect(result.first.annotated?).to be false
      end

      it 'has nil oid and tagger fields for lightweight tags' do
        result = command.call
        tag = result.first
        expect(tag.oid).to be_nil
        expect(tag.tagger_name).to be_nil
        expect(tag.tagger_email).to be_nil
        expect(tag.tagger_date).to be_nil
        expect(tag.message).to be_nil
      end

      it 'has target_oid pointing to the commit' do
        result = command.call
        tag = result.first
        # For lightweight tags, target_oid should be a valid commit SHA
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
        result = command.call
        expect(result.size).to eq(1)
        tag = result.first
        expect(tag.name).to eq('v2.0.0')
        expect(tag.oid).to match(/^[0-9a-f]{40}$/)
        expect(tag.target_oid).to match(/^[0-9a-f]{40}$/)
        expect(tag.objecttype).to eq('tag')
      end

      it 'identifies annotated tags correctly' do
        result = command.call
        expect(result.first.annotated?).to be true
        expect(result.first.lightweight?).to be false
      end

      it 'has tagger fields populated for annotated tags' do
        result = command.call
        tag = result.first
        expect(tag.tagger_name).not_to be_nil
        expect(tag.tagger_email).not_to be_nil
        # iso8601-strict format: YYYY-MM-DDTHH:MM:SS±HH:MM or YYYY-MM-DDTHH:MM:SSZ
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
        # Create tag with multi-line message
        repo.add_tag('v1.0.0', annotate: true, message: multiline_message)
        # Create another tag to verify multi-tag parsing still works
        repo.add_tag('v1.1.0', annotate: true, message: 'Simple message')
      end

      it 'captures full multi-line message' do
        result = command.call
        v1_tag = result.find { |t| t.name == 'v1.0.0' }
        expect(v1_tag.message).to eq(multiline_message)
      end

      it 'preserves newlines in message' do
        result = command.call
        v1_tag = result.find { |t| t.name == 'v1.0.0' }
        expect(v1_tag.message).to include("\n")
        expect(v1_tag.message.lines.count).to eq(5)
      end

      it 'does not affect parsing of other tags' do
        result = command.call
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
        result = command.call
        expect(result.size).to eq(3)
        expect(result.map(&:name)).to contain_exactly('v1.0.0', 'v1.1.0', 'v2.0.0')
      end

      it 'correctly identifies tag types' do
        result = command.call
        v1_tag = result.find { |t| t.name == 'v1.0.0' }
        v1_1_tag = result.find { |t| t.name == 'v1.1.0' }
        v2_tag = result.find { |t| t.name == 'v2.0.0' }

        expect(v1_tag.lightweight?).to be true
        expect(v1_1_tag.annotated?).to be true
        expect(v2_tag.lightweight?).to be true
      end
    end

    context 'with pattern filtering' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
        repo.add_tag('v1.1.0')
        repo.add_tag('v2.0.0')
        repo.add_tag('release-1.0')
      end

      it 'filters tags by pattern' do
        result = command.call('v1.*')
        expect(result.map(&:name)).to contain_exactly('v1.0.0', 'v1.1.0')
      end

      it 'filters tags by multiple patterns' do
        result = command.call('v1.*', 'release-*')
        expect(result.map(&:name)).to contain_exactly('v1.0.0', 'v1.1.0', 'release-1.0')
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
        result = command.call
        expect(result.map(&:name)).to include('release/v1.0')
      end

      it 'handles tags with hyphens' do
        result = command.call
        expect(result.map(&:name)).to include('feature-branch-tag')
      end
    end

    context 'with sorting' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.10.0')
        repo.add_tag('v1.2.0')
        repo.add_tag('v1.20.0')
      end

      it 'sorts tags by refname' do
        result = command.call(sort: 'refname')
        expect(result.map(&:name)).to eq(['v1.10.0', 'v1.2.0', 'v1.20.0'])
      end

      it 'sorts tags by version' do
        result = command.call(sort: 'version:refname')
        expect(result.map(&:name)).to eq(['v1.2.0', 'v1.10.0', 'v1.20.0'])
      end
    end

    context 'with ignore_case option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        # Create tags with mixed case to test case-insensitive behavior
        repo.add_tag('Alpha')
        repo.add_tag('beta')
        repo.add_tag('CHARLIE')
        repo.add_tag('delta')
      end

      it 'returns all tags regardless of ignore_case setting' do
        result = command.call
        expect(result.map(&:name)).to contain_exactly('Alpha', 'beta', 'CHARLIE', 'delta')

        result_ignore_case = command.call(ignore_case: true)
        expect(result_ignore_case.map(&:name)).to contain_exactly('Alpha', 'beta', 'CHARLIE', 'delta')
      end

      it 'affects sorting order when combined with sort option' do
        # Without ignore_case: uppercase letters sort before lowercase (ASCII order)
        # Default refname sort: A < B < ... < Z < a < b < ... < z
        result = command.call(sort: 'refname')
        # Alpha (A=65), CHARLIE (C=67), beta (b=98), delta (d=100)
        expect(result.map(&:name)).to eq(%w[Alpha CHARLIE beta delta])

        # With ignore_case: case-insensitive sorting
        result_ignore_case = command.call(sort: 'refname', ignore_case: true)
        # Should sort alphabetically ignoring case: Alpha, beta, CHARLIE, delta
        expect(result_ignore_case.map(&:name)).to eq(%w[Alpha beta CHARLIE delta])
      end

      it 'affects pattern matching when filtering' do
        # Without ignore_case: pattern is case-sensitive
        # '*eta' matches only 'beta' (not 'delta' which ends in 'a')
        result = command.call('*eta')
        expect(result.map(&:name)).to contain_exactly('beta')

        # With ignore_case: pattern matching is case-insensitive
        # '[Aa]*' matches tags starting with A or a
        result_ignore_case = command.call('[Aa]*', ignore_case: true)
        expect(result_ignore_case.map(&:name)).to include('Alpha')
      end

      it 'works with single-character pattern matching' do
        # Create additional tags to test pattern matching
        repo.add_tag('ALPHA-2')

        # Case-insensitive match for tags starting with 'alpha' (any case)
        result = command.call('alpha*', ignore_case: true)
        expect(result.map(&:name)).to contain_exactly('Alpha', 'ALPHA-2')

        # Without ignore_case, 'alpha*' only matches lowercase
        result_sensitive = command.call('alpha*')
        expect(result_sensitive.map(&:name)).to be_empty
      end
    end
  end
end
