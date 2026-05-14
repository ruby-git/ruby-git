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
end
