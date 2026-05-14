# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/stashing'

# Integration-level coverage for Git::Repository::Stashing facade methods is
# provided by the underlying command integration tests:
#   spec/integration/git/commands/stash/push_spec.rb   (stash_save)
#   spec/integration/git/commands/stash/apply_spec.rb  (stash_apply)
# Each facade method delegates to a single Git::Commands::Stash::* class with no
# multi-command orchestration. The unit specs below cover each facade method's own
# behavior; the command integration specs cover end-to-end git execution.

RSpec.describe Git::Repository::Stashing do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  let(:push_command) { instance_double(Git::Commands::Stash::Push) }

  before do
    allow(Git::Commands::Stash::Push).to receive(:new).with(execution_context).and_return(push_command)
  end

  describe '#stashes_all' do
    let(:list_command) { instance_double(Git::Commands::Stash::List) }

    before do
      allow(Git::Commands::Stash::List).to receive(:new).with(execution_context).and_return(list_command)
    end

    context 'when there are no stash entries' do
      let(:list_result) { command_result('') }
      let(:stash_infos) { [] }

      before do
        allow(list_command).to receive(:call).with(no_args).and_return(list_result)
        allow(Git::Parsers::Stash).to receive(:parse_list).with('').and_return(stash_infos)
      end

      it 'returns an empty array' do
        expect(described_instance.stashes_all).to eq([])
      end
    end

    context 'when there are stash entries with branch-prefixed messages' do
      let(:list_result) { command_result('fixture') }
      let(:stash_info_older) { instance_double(Git::StashInfo, message: 'On main: Fix bug') }
      let(:stash_info_newer) { instance_double(Git::StashInfo, message: 'On main: Add feature') }
      # parse_list returns newest-first; reversed to oldest-first
      let(:stash_infos) { [stash_info_newer, stash_info_older] }

      before do
        allow(list_command).to receive(:call).with(no_args).and_return(list_result)
        allow(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(stash_infos)
      end

      it 'constructs Git::Commands::Stash::List with the execution context' do
        expect(Git::Commands::Stash::List).to receive(:new).with(execution_context).and_return(list_command)
        allow(list_command).to receive(:call).and_return(list_result)
        described_instance.stashes_all
      end

      it 'calls Git::Commands::Stash::List#call with no arguments' do
        expect(list_command).to receive(:call).with(no_args).and_return(list_result)
        described_instance.stashes_all
      end

      it 'passes the command stdout to Git::Parsers::Stash.parse_list' do
        expect(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(stash_infos)
        described_instance.stashes_all
      end

      it 'returns stash entries in oldest-first order with sequential indices' do
        expect(described_instance.stashes_all).to eq([[0, 'Fix bug'], [1, 'Add feature']])
      end

      it 'strips the branch prefix from the message' do
        result = described_instance.stashes_all
        expect(result.map(&:last)).to eq(['Fix bug', 'Add feature'])
      end
    end

    context 'when a stash entry has no branch prefix (custom message)' do
      let(:list_result) { command_result('fixture') }
      let(:stash_info) { instance_double(Git::StashInfo, message: 'custom message') }

      before do
        allow(list_command).to receive(:call).and_return(list_result)
        allow(Git::Parsers::Stash).to receive(:parse_list).and_return([stash_info])
      end

      it 'returns the message unchanged' do
        expect(described_instance.stashes_all).to eq([[0, 'custom message']])
      end
    end

    context 'when a stash entry has a message with an internal colon (e.g. "saving: note")' do
      let(:list_result) { command_result('fixture') }
      let(:stash_info) { instance_double(Git::StashInfo, message: 'On main: saving: note') }

      before do
        allow(list_command).to receive(:call).and_return(list_result)
        allow(Git::Parsers::Stash).to receive(:parse_list).and_return([stash_info])
      end

      it 'strips only the first prefix, keeping subsequent colons in the message' do
        expect(described_instance.stashes_all).to eq([[0, 'saving: note']])
      end
    end
  end

  describe '#stash_save' do
    context 'when there are local changes to save' do
      let(:push_result) { command_result('Saved working directory and index state On main: WIP: feature work') }

      it 'calls Git::Commands::Stash::Push with the given message' do
        expect(push_command).to receive(:call).with(message: 'WIP: feature work').and_return(push_result)
        described_instance.stash_save('WIP: feature work')
      end

      it 'returns true' do
        allow(push_command).to receive(:call).with(message: 'WIP: feature work').and_return(push_result)
        expect(described_instance.stash_save('WIP: feature work')).to be(true)
      end
    end

    context 'when there are no local changes to save' do
      let(:push_result) { command_result('No local changes to save') }

      it 'calls Git::Commands::Stash::Push with the given message' do
        expect(push_command).to receive(:call).with(message: 'empty').and_return(push_result)
        described_instance.stash_save('empty')
      end

      it 'returns false' do
        allow(push_command).to receive(:call).with(message: 'empty').and_return(push_result)
        expect(described_instance.stash_save('empty')).to be(false)
      end
    end
  end

  describe '#stash_apply' do
    let(:apply_command) { instance_double(Git::Commands::Stash::Apply) }
    let(:apply_result) { command_result('HEAD is now at abc1234 Initial commit') }

    before do
      allow(Git::Commands::Stash::Apply).to receive(:new).with(execution_context).and_return(apply_command)
    end

    context 'when no id is given' do
      it 'calls Git::Commands::Stash::Apply#call with nil' do
        expect(apply_command).to receive(:call).with(nil).and_return(apply_result)
        described_instance.stash_apply
      end

      it 'returns the stdout string' do
        allow(apply_command).to receive(:call).with(nil).and_return(apply_result)
        expect(described_instance.stash_apply).to eq('HEAD is now at abc1234 Initial commit')
      end
    end

    context 'when a string stash reference is given' do
      it 'calls Git::Commands::Stash::Apply#call with the reference' do
        expect(apply_command).to receive(:call).with('stash@{1}').and_return(apply_result)
        described_instance.stash_apply('stash@{1}')
      end

      it 'returns the stdout string' do
        allow(apply_command).to receive(:call).with('stash@{1}').and_return(apply_result)
        expect(described_instance.stash_apply('stash@{1}')).to eq('HEAD is now at abc1234 Initial commit')
      end
    end

    context 'when an integer index is given' do
      it 'calls Git::Commands::Stash::Apply#call with the integer' do
        expect(apply_command).to receive(:call).with(2).and_return(apply_result)
        described_instance.stash_apply(2)
      end
    end
  end

  describe '#stash_clear' do
    let(:clear_command) { instance_double(Git::Commands::Stash::Clear) }
    let(:clear_result) { command_result('') }

    before do
      allow(Git::Commands::Stash::Clear).to receive(:new).with(execution_context).and_return(clear_command)
    end

    it 'calls Git::Commands::Stash::Clear with the execution context' do
      expect(clear_command).to receive(:call).with(no_args).and_return(clear_result)
      described_instance.stash_clear
    end

    it 'returns the stdout string' do
      allow(clear_command).to receive(:call).and_return(clear_result)
      expect(described_instance.stash_clear).to eq('')
    end
  end
end
