# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/configuring'
require 'git/execution_context/repository'

# Integration tests for Git::Repository::Configuring.
#
# #config (list mode) performs facade-owned post-processing: it parses the raw
# stdout of `git config --list` into a Ruby Hash. A real git invocation is
# needed to confirm the parsing handles actual git output correctly.
#
# Single-command get and set modes are covered by dedicated command integration
# tests under spec/integration/git/commands/config_option_syntax/{get,set,list}_spec.rb.
# Error-path assertions and argument-forwarding tests are skipped here because
# they test command behavior, not the facade. The set→get round-trip test is
# retained to confirm the facade's dispatch logic routes both modes correctly
# end-to-end against real git.

RSpec.describe Git::Repository::Configuring, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#config' do
    context 'when called with no arguments' do
      it 'returns a Hash containing expected config keys' do
        result = described_instance.config
        expect(result).to be_a(Hash)
        expect(result).to include('user.name', 'user.email')
      end

      it 'returns the configured user.name value' do
        result = described_instance.config
        expect(result['user.name']).to eq('Test User')
      end
    end

    context 'when called with name and value' do
      it 'sets the value and a subsequent get returns the new value' do
        described_instance.config('user.name', 'NewName')
        expect(described_instance.config('user.name')).to eq('NewName')
      end
    end
  end
end
