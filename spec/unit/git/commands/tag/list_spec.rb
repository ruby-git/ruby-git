# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/list'

RSpec.describe Git::Commands::Tag::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Helper to expect command call - verifies the command is called with specific arguments
  def expect_command(*args, stdout: '')
    expect(execution_context).to receive(:command).with(*args, any_args).and_return(command_result(stdout))
  end

  # Helper to stub command call for parsing tests where other expectations do the verification
  def allow_command(*args, stdout: '')
    allow(execution_context).to receive(:command).with(*args, any_args).and_return(command_result(stdout))
  end

  describe '#call' do
    let(:format_arg) { "--format=#{described_class::FORMAT_STRING}" }

    context 'with no options (basic list)' do
      it 'calls git tag --list with format string' do
        expect_command('tag', '--list', format_arg)
        command.call
      end
    end

    context 'with patterns' do
      it 'adds a single pattern argument' do
        expect_command('tag', '--list', format_arg, 'v1.*')
        command.call('v1.*')
      end

      it 'adds multiple pattern arguments' do
        expect_command('tag', '--list', format_arg, 'v1.*', 'v2.*')
        command.call('v1.*', 'v2.*')
      end
    end

    context 'with :sort option' do
      it 'adds --sort=<key> with single value' do
        expect_command('tag', '--list', format_arg, '--sort=refname')
        command.call(sort: 'refname')
      end

      it 'adds multiple --sort=<key> with array of values' do
        expect_command('tag', '--list', format_arg, '--sort=refname', '--sort=-creatordate')
        command.call(sort: ['refname', '-creatordate'])
      end

      it 'supports version:refname sort key' do
        expect_command('tag', '--list', format_arg, '--sort=version:refname')
        command.call(sort: 'version:refname')
      end
    end

    context 'with :contains option' do
      it 'adds --contains <commit>' do
        expect_command('tag', '--list', format_arg, '--contains', 'abc123')
        command.call(contains: 'abc123')
      end
    end

    context 'with :no_contains option' do
      it 'adds --no-contains <commit>' do
        expect_command('tag', '--list', format_arg, '--no-contains', 'abc123')
        command.call(no_contains: 'abc123')
      end
    end

    context 'with :merged option' do
      it 'adds --merged <commit>' do
        expect_command('tag', '--list', format_arg, '--merged', 'main')
        command.call(merged: 'main')
      end
    end

    context 'with :no_merged option' do
      it 'adds --no-merged <commit>' do
        expect_command('tag', '--list', format_arg, '--no-merged', 'main')
        command.call(no_merged: 'main')
      end
    end

    context 'with :points_at option' do
      it 'adds --points-at <object>' do
        expect_command('tag', '--list', format_arg, '--points-at', 'HEAD')
        command.call(points_at: 'HEAD')
      end
    end

    context 'with multiple options combined' do
      it 'combines flags correctly' do
        expect_command('tag', '--list', format_arg, '--sort=refname', '--contains', 'abc123', 'v1.*')
        command.call('v1.*', sort: 'refname', contains: 'abc123')
      end

      it 'combines multiple patterns with options' do
        expect_command('tag', '--list', format_arg, '--merged', 'main', 'release-*', 'v*')
        command.call('release-*', 'v*', merged: 'main')
      end
    end

    context 'when parsing tag output' do
      let(:tag_output) do
        [
          "v1.0.0\x1fabc123def456\x1f111111111111\x1ftag\x1fJohn Doe\x1f<john@example.com>\x1f" \
          "2024-01-15T10:30:00-08:00\x1fRelease version 1.0.0",
          "v1.1.0\x1fdef456abc123\x1f\x1fcommit\x1f\x1f\x1f\x1f",
          "v2.0.0-beta\x1f789abc456def\x1f222222222222\x1ftag\x1fJane Smith\x1f<jane@example.com>\x1f" \
          "2024-02-20T14:00:00-05:00\x1fBeta release"
        ].join("\n")
      end

      it 'returns parsed tag data as array of TagInfo objects' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result).to all(be_a(Git::TagInfo))
      end

      it 'extracts tag names correctly' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result.map(&:name)).to eq(%w[v1.0.0 v1.1.0 v2.0.0-beta])
      end

      it 'extracts oid correctly for annotated tags' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result[0].oid).to eq('abc123def456')
        expect(result[2].oid).to eq('789abc456def')
      end

      it 'sets oid to nil for lightweight tags' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result[1].oid).to be_nil
      end

      it 'extracts target_oid correctly for annotated tags (dereferenced commit)' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result[0].target_oid).to eq('111111111111')
        expect(result[2].target_oid).to eq('222222222222')
      end

      it 'extracts target_oid correctly for lightweight tags (objectname)' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result[1].target_oid).to eq('def456abc123')
      end

      it 'extracts object type correctly' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result[0].objecttype).to eq('tag')
        expect(result[1].objecttype).to eq('commit')
        expect(result[2].objecttype).to eq('tag')
      end

      it 'identifies annotated tags' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result[0].annotated?).to be true
        expect(result[1].annotated?).to be false
        expect(result[2].annotated?).to be true
      end

      it 'identifies lightweight tags' do
        allow_command('tag', '--list', format_arg, stdout: tag_output)
        result = command.call
        expect(result[0].lightweight?).to be false
        expect(result[1].lightweight?).to be true
        expect(result[2].lightweight?).to be false
      end
    end

    context 'with annotated tags' do
      let(:annotated_tag_output) do
        "v1.0.0\x1fabc123def456\x1f111222333444\x1ftag\x1fJohn Doe\x1f<john@example.com>\x1f" \
          "2024-01-15T10:30:00-08:00\x1fRelease version 1.0.0"
      end

      it 'returns TagInfo with all metadata fields populated' do
        allow_command('tag', '--list', format_arg, stdout: annotated_tag_output)
        result = command.call
        tag = result.first
        expect(tag.name).to eq('v1.0.0')
        expect(tag.oid).to eq('abc123def456')
        expect(tag.target_oid).to eq('111222333444')
        expect(tag.objecttype).to eq('tag')
        expect(tag.tagger_name).to eq('John Doe')
        expect(tag.tagger_email).to eq('<john@example.com>')
        expect(tag.tagger_date).to eq('2024-01-15T10:30:00-08:00')
        expect(tag.message).to eq('Release version 1.0.0')
      end
    end

    context 'with lightweight tags' do
      let(:lightweight_tag_output) { "v2.0.0\x1fdef456abc123\x1f\x1fcommit\x1f\x1f\x1f\x1f\x1f" }

      it 'returns TagInfo with tagger fields as nil' do
        allow_command('tag', '--list', format_arg, stdout: lightweight_tag_output)
        result = command.call
        tag = result.first
        expect(tag.name).to eq('v2.0.0')
        expect(tag.oid).to be_nil
        expect(tag.target_oid).to eq('def456abc123')
        expect(tag.objecttype).to eq('commit')
        expect(tag.tagger_name).to be_nil
        expect(tag.tagger_email).to be_nil
        expect(tag.tagger_date).to be_nil
        expect(tag.message).to be_nil
      end
    end

    context 'with empty result' do
      it 'returns an empty array' do
        allow_command('tag', '--list', format_arg)
        result = command.call
        expect(result).to eq([])
      end
    end

    context 'with special characters in tag names and messages' do
      it 'handles unicode in tag names' do
        unicode_output = "tag-with-emoji-🚀\x1fabc123\x1f111222333\x1ftag\x1fDev\x1f<dev@example.com>\x1f" \
                         "2024-01-01T00:00:00Z\x1fTest"
        allow_command('tag', '--list', format_arg, stdout: unicode_output)
        result = command.call
        expect(result.first.name).to eq('tag-with-emoji-🚀')
      end

      it 'handles slashes in tag names' do
        slash_output = "release/v1.0\x1fabc123\x1f\x1fcommit\x1f\x1f\x1f\x1f\x1f"
        allow_command('tag', '--list', format_arg, stdout: slash_output)
        result = command.call
        expect(result.first.name).to eq('release/v1.0')
      end

      it 'handles unicode in messages' do
        unicode_message_output = "v1.0\x1fabc123\x1f111222333\x1ftag\x1fDev\x1f<dev@example.com>\x1f" \
                                 "2024-01-01T00:00:00Z\x1fRelease 🎉"
        allow_command('tag', '--list', format_arg, stdout: unicode_message_output)
        result = command.call
        expect(result.first.message).to eq('Release 🎉')
      end

      it 'handles empty message for annotated tags' do
        no_message_output = "v1.0\x1fabc123\x1f111222333\x1ftag\x1fDev\x1f<dev@example.com>\x1f2024-01-01T00:00:00Z\x1f"
        allow_command('tag', '--list', format_arg, stdout: no_message_output)
        result = command.call
        expect(result.first.message).to be_nil
      end
    end

    context 'with malformed output' do
      it 'raises UnexpectedResultError with helpful message for wrong field count' do
        bad_output = "v1.0\x1fabc123\x1ftag" # Only 3 fields instead of 8
        allow_command('tag', '--list', format_arg, stdout: bad_output)

        expect { command.call }.to raise_error(Git::UnexpectedResultError) do |error|
          expect(error.message).to include('Unexpected line')
          expect(error.message).to include('at index 0')
          expect(error.message).to include('Expected 8 fields')
          expect(error.message).to include('got 3')
        end
      end
    end
  end
end
