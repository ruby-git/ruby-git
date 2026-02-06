# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/list'

# Integration tests for Git::Commands::Tag::List
#
# These tests verify the command's execution behavior. Parsing logic is
# tested separately in spec/integration/git/tag_parser_spec.rb.
#
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

    context 'with tags' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0')
        repo.add_tag('v2.0.0', annotate: true, message: 'Release version 2.0.0')
      end

      it 'returns all tags as TagInfo objects' do
        result = command.call
        expect(result).to all(be_a(Git::TagInfo))
        expect(result.map(&:name)).to contain_exactly('v1.0.0', 'v2.0.0')
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

    context 'with :contains option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('First commit')
        repo.add_tag('v1.0.0')

        write_file('file2.txt', 'content2')
        repo.add('file2.txt')
        repo.commit('Second commit')
        repo.add_tag('v2.0.0')
      end

      it 'filters tags containing the commit' do
        head_sha = repo.lib.command('rev-parse', 'HEAD').stdout.strip
        result = command.call(contains: head_sha)
        expect(result.map(&:name)).to contain_exactly('v2.0.0')
      end
    end

    context 'with :ignore_case option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('Alpha')
        repo.add_tag('beta')
      end

      it 'affects sorting order when combined with sort option' do
        result = command.call(sort: 'refname')
        expect(result.map(&:name)).to eq(%w[Alpha beta])

        result_ignore_case = command.call(sort: 'refname', ignore_case: true)
        expect(result_ignore_case.map(&:name)).to eq(%w[Alpha beta])
      end
    end
  end
end
