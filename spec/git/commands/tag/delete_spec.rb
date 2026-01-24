# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/delete'

RSpec.describe Git::Commands::Tag::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with single tag name' do
      it 'calls git tag -d with the tag name' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'v1.0.0')
        command.call('v1.0.0')
      end
    end

    context 'with multiple tag names' do
      it 'deletes all specified tags in one command' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'v1.0.0', 'v1.1.0', 'v2.0.0')
        command.call('v1.0.0', 'v1.1.0', 'v2.0.0')
      end

      it 'handles two tags' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'old-tag', 'newer-tag')
        command.call('old-tag', 'newer-tag')
      end
    end

    context 'with various tag name formats' do
      it 'handles semver tags' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'v1.2.3')
        command.call('v1.2.3')
      end

      it 'handles tags with slashes' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'release/v1.0')
        command.call('release/v1.0')
      end

      it 'handles tags with hyphens and underscores' do
        expect(execution_context).to receive(:command).with('tag', '-d', 'my-tag_name')
        command.call('my-tag_name')
      end
    end
  end
end
