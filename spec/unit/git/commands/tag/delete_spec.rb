# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/delete'
require 'git/commands/tag/list'
require 'git/tag_info'
require 'git/tag_delete_result'
require 'git/tag_delete_failure'

RSpec.describe Git::Commands::Tag::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:list_command) { instance_double(Git::Commands::Tag::List) }

  let(:tag_v1) do
    Git::TagInfo.new(
      name: 'v1.0.0', sha: 'abc123', objecttype: 'commit',
      tagger_name: nil, tagger_email: nil, tagger_date: nil, message: nil
    )
  end
  let(:tag_v2) do
    Git::TagInfo.new(
      name: 'v2.0.0', sha: 'def456', objecttype: 'commit',
      tagger_name: nil, tagger_email: nil, tagger_date: nil, message: nil
    )
  end
  let(:tag_v3) do
    Git::TagInfo.new(
      name: 'v3.0.0', sha: 'ghi789', objecttype: 'commit',
      tagger_name: nil, tagger_email: nil, tagger_date: nil, message: nil
    )
  end

  before do
    allow(Git::Commands::Tag::List).to receive(:new).with(execution_context).and_return(list_command)
  end

  describe '#call' do
    context 'when all tags are successfully deleted' do
      context 'with single tag name' do
        before do
          allow(list_command).to receive(:call).and_return([tag_v1])
        end

        it 'calls git tag -d with the tag name' do
          expect(execution_context).to receive(:command).with('tag', '-d', 'v1.0.0')
                                                        .and_return("Deleted tag 'v1.0.0' (was abc123)\n")
          command.call('v1.0.0')
        end

        it 'returns TagDeleteResult with the deleted tag' do
          allow(execution_context).to receive(:command).with('tag', '-d', 'v1.0.0')
                                                       .and_return("Deleted tag 'v1.0.0' (was abc123)\n")

          result = command.call('v1.0.0')

          expect(result).to be_a(Git::TagDeleteResult)
          expect(result.deleted.map(&:name)).to eq(['v1.0.0'])
          expect(result.not_deleted).to be_empty
          expect(result.success?).to be true
        end
      end

      context 'with multiple tag names' do
        let(:delete_output) do
          "Deleted tag 'v1.0.0' (was abc123)\n" \
            "Deleted tag 'v2.0.0' (was def456)\n" \
            "Deleted tag 'v3.0.0' (was ghi789)\n"
        end

        before do
          allow(list_command).to receive(:call).and_return([tag_v1, tag_v2, tag_v3])
        end

        it 'deletes all specified tags in one command' do
          expect(execution_context).to receive(:command)
            .with('tag', '-d', 'v1.0.0', 'v2.0.0', 'v3.0.0')
            .and_return(delete_output)
          command.call('v1.0.0', 'v2.0.0', 'v3.0.0')
        end

        it 'returns TagDeleteResult with all deleted tags' do
          allow(execution_context).to receive(:command)
            .with('tag', '-d', 'v1.0.0', 'v2.0.0', 'v3.0.0')
            .and_return(delete_output)

          result = command.call('v1.0.0', 'v2.0.0', 'v3.0.0')

          expect(result.deleted.map(&:name)).to eq(%w[v1.0.0 v2.0.0 v3.0.0])
          expect(result.not_deleted).to be_empty
          expect(result.success?).to be true
        end
      end
    end

    context 'when some tags do not exist (partial failure)' do
      let(:failed_error) do
        result = double('CommandLineResult',
                        git_cmd: %w[git tag -d v1.0.0 nonexistent v2.0.0],
                        status: double('Status', exitstatus: 1),
                        stderr: "error: tag 'nonexistent' not found.",
                        stdout: "Deleted tag 'v1.0.0' (was abc123)\nDeleted tag 'v2.0.0' (was def456)\n")
        Git::FailedError.new(result)
      end

      before do
        allow(list_command).to receive(:call).and_return([tag_v1, tag_v2])
      end

      it 'returns TagDeleteResult with deleted and not_deleted tags' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'v1.0.0', 'nonexistent', 'v2.0.0')
                                                      .and_raise(failed_error)

        result = command.call('v1.0.0', 'nonexistent', 'v2.0.0')

        expect(result.deleted.map(&:name)).to eq(['v1.0.0', 'v2.0.0'])
        expect(result.not_deleted.size).to eq(1)
        expect(result.not_deleted.first.name).to eq('nonexistent')
        expect(result.not_deleted.first.error_message).to include("tag 'nonexistent' not found")
        expect(result.success?).to be false
      end
    end

    context 'when all tags fail to delete' do
      let(:failed_error) do
        result = double('CommandLineResult',
                        git_cmd: %w[git tag -d nonexistent1 nonexistent2],
                        status: double('Status', exitstatus: 1),
                        stderr: "error: tag 'nonexistent1' not found.\nerror: tag 'nonexistent2' not found.",
                        stdout: '')
        Git::FailedError.new(result)
      end

      before do
        allow(list_command).to receive(:call).and_return([])
      end

      it 'returns TagDeleteResult with all tags in not_deleted' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'nonexistent1', 'nonexistent2')
                                                      .and_raise(failed_error)

        result = command.call('nonexistent1', 'nonexistent2')

        expect(result.deleted).to be_empty
        expect(result.not_deleted.map(&:name)).to eq(%w[nonexistent1 nonexistent2])
        expect(result.success?).to be false
      end
    end

    context 'when a non-partial-failure error occurs' do
      let(:other_error) do
        result = double('CommandLineResult',
                        git_cmd: %w[git tag -d v1.0.0],
                        status: double('Status', exitstatus: 128),
                        stderr: 'fatal: some unexpected error',
                        stdout: '')
        Git::FailedError.new(result)
      end

      before do
        allow(list_command).to receive(:call).and_return([tag_v1])
      end

      it 're-raises the error' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'v1.0.0')
                                                      .and_raise(other_error)

        expect { command.call('v1.0.0') }.to raise_error(Git::FailedError)
      end
    end

    context 'with various tag name formats' do
      let(:lightweight_tag) do
        lambda do |name|
          Git::TagInfo.new(
            name: name, sha: 'abc', objecttype: 'commit',
            tagger_name: nil, tagger_email: nil, tagger_date: nil, message: nil
          )
        end
      end

      it 'handles semver tags' do
        allow(list_command).to receive(:call).and_return([lightweight_tag.call('v1.2.3')])
        expect(execution_context).to receive(:command)
          .with('tag', '-d', 'v1.2.3')
          .and_return("Deleted tag 'v1.2.3' (was abc)\n")

        result = command.call('v1.2.3')
        expect(result.deleted.first.name).to eq('v1.2.3')
      end

      it 'handles tags with slashes' do
        allow(list_command).to receive(:call).and_return([lightweight_tag.call('release/v1.0')])
        expect(execution_context).to receive(:command)
          .with('tag', '-d', 'release/v1.0')
          .and_return("Deleted tag 'release/v1.0' (was abc)\n")

        result = command.call('release/v1.0')
        expect(result.deleted.first.name).to eq('release/v1.0')
      end

      it 'handles tags with hyphens and underscores' do
        allow(list_command).to receive(:call).and_return([lightweight_tag.call('my-tag_name')])
        expect(execution_context).to receive(:command)
          .with('tag', '-d', 'my-tag_name')
          .and_return("Deleted tag 'my-tag_name' (was abc)\n")

        result = command.call('my-tag_name')
        expect(result.deleted.first.name).to eq('my-tag_name')
      end
    end
  end
end
