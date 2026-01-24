# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/list'

RSpec.describe Git::Commands::Tag::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options (basic list)' do
      it 'calls git tag --list with no additional arguments' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list').and_return([])
        command.call
      end
    end

    context 'with patterns' do
      it 'adds a single pattern argument' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', 'v1.*').and_return([])
        command.call('v1.*')
      end

      it 'adds multiple pattern arguments' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', 'v1.*', 'v2.*').and_return([])
        command.call('v1.*', 'v2.*')
      end
    end

    context 'with :sort option' do
      it 'adds --sort=<key> with single value' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', '--sort=refname').and_return([])
        command.call(sort: 'refname')
      end

      it 'adds multiple --sort=<key> with array of values' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--sort=refname', '--sort=-creatordate'
        ).and_return([])
        command.call(sort: ['refname', '-creatordate'])
      end

      it 'supports version:refname sort key' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--sort=version:refname'
        ).and_return([])
        command.call(sort: 'version:refname')
      end
    end

    context 'with :contains option' do
      it 'adds --contains <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--contains', 'abc123'
        ).and_return([])
        command.call(contains: 'abc123')
      end
    end

    context 'with :no_contains option' do
      it 'adds --no-contains <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--no-contains', 'abc123'
        ).and_return([])
        command.call(no_contains: 'abc123')
      end
    end

    context 'with :merged option' do
      it 'adds --merged <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--merged', 'main'
        ).and_return([])
        command.call(merged: 'main')
      end
    end

    context 'with :no_merged option' do
      it 'adds --no-merged <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--no-merged', 'main'
        ).and_return([])
        command.call(no_merged: 'main')
      end
    end

    context 'with :points_at option' do
      it 'adds --points-at <object>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--points-at', 'HEAD'
        ).and_return([])
        command.call(points_at: 'HEAD')
      end
    end

    context 'with multiple options combined' do
      it 'combines flags correctly' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--sort=refname', '--contains', 'abc123', 'v1.*'
        ).and_return([])
        command.call('v1.*', sort: 'refname', contains: 'abc123')
      end

      it 'combines multiple patterns with options' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', '--merged', 'main', 'release-*', 'v*'
        ).and_return([])
        command.call('release-*', 'v*', merged: 'main')
      end
    end

    context 'when parsing tag output' do
      let(:tag_output) do
        [
          'v1.0.0',
          'v1.1.0',
          'v2.0.0-beta'
        ]
      end

      it 'returns parsed tag data as array of TagInfo objects' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list').and_return(tag_output)
        result = command.call
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result).to all(be_a(Git::TagInfo))
      end

      it 'extracts tag names correctly' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list').and_return(tag_output)
        result = command.call
        expect(result.map(&:name)).to eq(%w[v1.0.0 v1.1.0 v2.0.0-beta])
      end
    end

    context 'with annotated tags' do
      it 'returns TagInfo with name populated (metadata fields are nil until format parsing is implemented)' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list').and_return(['v1.0.0'])
        result = command.call
        tag = result.first
        expect(tag.name).to eq('v1.0.0')
        # sha, objecttype, tagger_*, and message are nil for now
        # Future enhancement: use --format to populate these fields
        expect(tag.sha).to be_nil
      end
    end

    context 'with empty result' do
      it 'returns an empty array' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list').and_return([])
        result = command.call
        expect(result).to eq([])
      end
    end
  end
end
