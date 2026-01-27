# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/list'

RSpec.describe Git::Commands::Tag::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    let(:format_arg) { "--format=#{described_class::FORMAT_STRING}" }

    context 'with no options (basic list)' do
      it 'calls git tag --list with format string' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return([])
        command.call
      end
    end

    context 'with patterns' do
      it 'adds a single pattern argument' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg, 'v1.*').and_return([])
        command.call('v1.*')
      end

      it 'adds multiple pattern arguments' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg, 'v1.*',
                                                                  'v2.*').and_return([])
        command.call('v1.*', 'v2.*')
      end
    end

    context 'with :sort option' do
      it 'adds --sort=<key> with single value' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg,
                                                                  '--sort=refname').and_return([])
        command.call(sort: 'refname')
      end

      it 'adds multiple --sort=<key> with array of values' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--sort=refname', '--sort=-creatordate'
        ).and_return([])
        command.call(sort: ['refname', '-creatordate'])
      end

      it 'supports version:refname sort key' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--sort=version:refname'
        ).and_return([])
        command.call(sort: 'version:refname')
      end
    end

    context 'with :contains option' do
      it 'adds --contains <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--contains', 'abc123'
        ).and_return([])
        command.call(contains: 'abc123')
      end
    end

    context 'with :no_contains option' do
      it 'adds --no-contains <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--no-contains', 'abc123'
        ).and_return([])
        command.call(no_contains: 'abc123')
      end
    end

    context 'with :merged option' do
      it 'adds --merged <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--merged', 'main'
        ).and_return([])
        command.call(merged: 'main')
      end
    end

    context 'with :no_merged option' do
      it 'adds --no-merged <commit>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--no-merged', 'main'
        ).and_return([])
        command.call(no_merged: 'main')
      end
    end

    context 'with :points_at option' do
      it 'adds --points-at <object>' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--points-at', 'HEAD'
        ).and_return([])
        command.call(points_at: 'HEAD')
      end
    end

    context 'with multiple options combined' do
      it 'combines flags correctly' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--sort=refname', '--contains', 'abc123', 'v1.*'
        ).and_return([])
        command.call('v1.*', sort: 'refname', contains: 'abc123')
      end

      it 'combines multiple patterns with options' do
        expect(execution_context).to receive(:command_lines).with(
          'tag', '--list', format_arg, '--merged', 'main', 'release-*', 'v*'
        ).and_return([])
        command.call('release-*', 'v*', merged: 'main')
      end
    end

    context 'when parsing tag output' do
      let(:tag_output) do
        [
          "v1.0.0\x1fabc123def456\x1ftag\x1fJohn Doe\x1f<john@example.com>\x1f" \
          "2024-01-15T10:30:00-08:00\x1fRelease version 1.0.0",
          "v1.1.0\x1fdef456abc123\x1fcommit\x1f\x1f\x1f\x1f",
          "v2.0.0-beta\x1f789abc456def\x1ftag\x1fJane Smith\x1f<jane@example.com>\x1f" \
          "2024-02-20T14:00:00-05:00\x1fBeta release"
        ]
      end

      it 'returns parsed tag data as array of TagInfo objects' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(tag_output)
        result = command.call
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result).to all(be_a(Git::TagInfo))
      end

      it 'extracts tag names correctly' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(tag_output)
        result = command.call
        expect(result.map(&:name)).to eq(%w[v1.0.0 v1.1.0 v2.0.0-beta])
      end

      it 'extracts SHA correctly' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(tag_output)
        result = command.call
        expect(result[0].sha).to eq('abc123def456')
        expect(result[1].sha).to eq('def456abc123')
        expect(result[2].sha).to eq('789abc456def')
      end

      it 'extracts object type correctly' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(tag_output)
        result = command.call
        expect(result[0].objecttype).to eq('tag')
        expect(result[1].objecttype).to eq('commit')
        expect(result[2].objecttype).to eq('tag')
      end

      it 'identifies annotated tags' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(tag_output)
        result = command.call
        expect(result[0].annotated?).to be true
        expect(result[1].annotated?).to be false
        expect(result[2].annotated?).to be true
      end

      it 'identifies lightweight tags' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(tag_output)
        result = command.call
        expect(result[0].lightweight?).to be false
        expect(result[1].lightweight?).to be true
        expect(result[2].lightweight?).to be false
      end
    end

    context 'with annotated tags' do
      let(:annotated_tag_output) do
        [
          "v1.0.0\x1fabc123def456\x1ftag\x1fJohn Doe\x1f<john@example.com>\x1f" \
          "2024-01-15T10:30:00-08:00\x1fRelease version 1.0.0"
        ]
      end

      it 'returns TagInfo with all metadata fields populated' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list',
                                                                  format_arg).and_return(annotated_tag_output)
        result = command.call
        tag = result.first
        expect(tag.name).to eq('v1.0.0')
        expect(tag.sha).to eq('abc123def456')
        expect(tag.objecttype).to eq('tag')
        expect(tag.tagger_name).to eq('John Doe')
        expect(tag.tagger_email).to eq('<john@example.com>')
        expect(tag.tagger_date).to eq('2024-01-15T10:30:00-08:00')
        expect(tag.message).to eq('Release version 1.0.0')
      end
    end

    context 'with lightweight tags' do
      let(:lightweight_tag_output) { ["v2.0.0\x1fdef456abc123\x1fcommit\x1f\x1f\x1f\x1f"] }

      it 'returns TagInfo with tagger fields as nil' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list',
                                                                  format_arg).and_return(lightweight_tag_output)
        result = command.call
        tag = result.first
        expect(tag.name).to eq('v2.0.0')
        expect(tag.sha).to eq('def456abc123')
        expect(tag.objecttype).to eq('commit')
        expect(tag.tagger_name).to be_nil
        expect(tag.tagger_email).to be_nil
        expect(tag.tagger_date).to be_nil
        expect(tag.message).to be_nil
      end
    end

    context 'with empty result' do
      it 'returns an empty array' do
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return([])
        result = command.call
        expect(result).to eq([])
      end
    end

    context 'with special characters in tag names and messages' do
      it 'handles unicode in tag names' do
        unicode_output = [
          "tag-with-emoji-🚀\x1fabc123\x1ftag\x1fDev\x1f<dev@example.com>\x1f" \
          "2024-01-01T00:00:00Z\x1fTest"
        ]
        expect(execution_context).to receive(:command_lines).with('tag', '--list',
                                                                  format_arg).and_return(unicode_output)
        result = command.call
        expect(result.first.name).to eq('tag-with-emoji-🚀')
      end

      it 'handles slashes in tag names' do
        slash_output = ["release/v1.0\x1fabc123\x1fcommit\x1f\x1f\x1f\x1f"]
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(slash_output)
        result = command.call
        expect(result.first.name).to eq('release/v1.0')
      end

      it 'handles unicode in messages' do
        unicode_message_output = [
          "v1.0\x1fabc123\x1ftag\x1fDev\x1f<dev@example.com>\x1f" \
          "2024-01-01T00:00:00Z\x1fRelease 🎉"
        ]
        expect(execution_context).to receive(:command_lines).with('tag', '--list',
                                                                  format_arg).and_return(unicode_message_output)
        result = command.call
        expect(result.first.message).to eq('Release 🎉')
      end

      it 'handles empty message for annotated tags' do
        no_message_output = ["v1.0\x1fabc123\x1ftag\x1fDev\x1f<dev@example.com>\x1f2024-01-01T00:00:00Z\x1f"]
        expect(execution_context).to receive(:command_lines).with('tag', '--list',
                                                                  format_arg).and_return(no_message_output)
        result = command.call
        expect(result.first.message).to be_nil
      end
    end

    context 'with malformed output' do
      it 'raises UnexpectedResultError with helpful message for wrong field count' do
        bad_output = ["v1.0\x1fabc123\x1ftag"] # Only 3 fields instead of 7
        expect(execution_context).to receive(:command_lines).with('tag', '--list', format_arg).and_return(bad_output)

        expect { command.call }.to raise_error(Git::UnexpectedResultError) do |error|
          expect(error.message).to include('Unexpected line')
          expect(error.message).to include('at index 0')
          expect(error.message).to include('Expected 7 fields')
          expect(error.message).to include('got 3')
        end
      end
    end
  end
end
