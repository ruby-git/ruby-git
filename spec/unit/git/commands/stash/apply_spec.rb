# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/apply'
require 'git/commands/stash/list'
require 'git/stash_info'

RSpec.describe Git::Commands::Stash::Apply do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:first_stash_info) do
    Git::StashInfo.new(
      index: 0, name: 'stash@{0}', oid: 'abc123', short_oid: 'abc123',
      branch: 'main', message: 'WIP on main: test',
      author_name: 'Test', author_email: 'test@example.com', author_date: '2024-01-01',
      committer_name: 'Test', committer_email: 'test@example.com', committer_date: '2024-01-01'
    )
  end
  let(:second_stash_info) do
    Git::StashInfo.new(
      index: 1, name: 'stash@{1}', oid: 'def456', short_oid: 'def456',
      branch: 'main', message: 'WIP on main: other',
      author_name: 'Test', author_email: 'test@example.com', author_date: '2024-01-01',
      committer_name: 'Test', committer_email: 'test@example.com', committer_date: '2024-01-01'
    )
  end
  let(:third_stash_info) do
    Git::StashInfo.new(
      index: 2, name: 'stash@{2}', oid: 'ghi789', short_oid: 'ghi789',
      branch: 'main', message: 'WIP on main: third',
      author_name: 'Test', author_email: 'test@example.com', author_date: '2024-01-01',
      committer_name: 'Test', committer_email: 'test@example.com', committer_date: '2024-01-01'
    )
  end
  let(:list_command) { instance_double(Git::Commands::Stash::List) }

  before do
    allow(Git::Commands::Stash::List).to receive(:new).with(execution_context).and_return(list_command)
    allow(list_command).to receive(:call).and_return([first_stash_info, second_stash_info, third_stash_info])
  end

  describe '#call' do
    context 'with no arguments (apply latest stash)' do
      it 'calls git stash apply' do
        expect(execution_context).to receive(:command).with('stash', 'apply')
        command.call
      end

      it 'returns the StashInfo for the applied stash' do
        allow(execution_context).to receive(:command).with('stash', 'apply')
        expect(command.call).to eq(first_stash_info)
      end
    end

    context 'with stash reference' do
      it 'applies specific stash by name' do
        expect(execution_context).to receive(:command).with('stash', 'apply', 'stash@{0}')
        command.call('stash@{0}')
      end

      it 'applies specific stash by index' do
        expect(execution_context).to receive(:command).with('stash', 'apply', 'stash@{2}')
        result = command.call('stash@{2}')
        expect(result).to eq(third_stash_info)
      end

      it 'applies stash using short form' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '1')
        result = command.call('1')
        expect(result).to eq(second_stash_info)
      end
    end

    context 'with :index option' do
      it 'adds --index flag to restore index state' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--index')
        command.call(index: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('stash', 'apply')
        command.call(index: false)
      end
    end

    context 'with stash reference and options' do
      it 'combines stash reference with index option' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--index', 'stash@{1}')
        result = command.call('stash@{1}', index: true)
        expect(result).to eq(second_stash_info)
      end
    end

    context 'when stash does not exist' do
      it 'raises UnexpectedResultError with actionable message' do
        expect do
          command.call('stash@{99}')
        end.to raise_error(
          Git::UnexpectedResultError,
          "Stash 'stash@{99}' does not exist. Run `git stash list` to see available stashes."
        )
      end

      it 'normalizes short form in error message' do
        expect do
          command.call('99')
        end.to raise_error(
          Git::UnexpectedResultError,
          "Stash 'stash@{99}' does not exist. Run `git stash list` to see available stashes."
        )
      end
    end
  end
end
