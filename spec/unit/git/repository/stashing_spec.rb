# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/stashing'

# Integration-level coverage for Git::Repository::Stashing#stash_save is provided
# by the underlying command integration test:
#   spec/integration/git/commands/stash/push_spec.rb
# The facade delegates to a single Git::Commands::Stash::Push class with no
# multi-command orchestration. The unit spec below covers the facade's own
# behavior (Boolean return-value derivation from stdout); the command integration
# spec covers end-to-end git execution.

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
end
