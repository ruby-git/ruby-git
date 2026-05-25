# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/configuring'
require 'git/execution_context/repository'

# Integration tests for Git::Repository::Configuring are warranted for one key reason:
#
# #config (list mode) performs facade-owned post-processing: it parses the raw
# stdout of `git config --list` into a Ruby Hash. A real git invocation is
# needed to confirm the parsing handles actual git output correctly.
#
# Note: dedicated integration tests for Git::Commands::ConfigOptionSyntax::Get,
# ::Set, and ::List already exist under
# spec/integration/git/commands/config_option_syntax/{get,set,list}_spec.rb.

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

    context 'when called with a key name' do
      it 'returns the configured value as a String' do
        result = described_instance.config('user.name')
        expect(result).to eq('Test User')
      end

      it 'raises Git::FailedError for a nonexistent key' do
        expect { described_instance.config('nonexistent.key') }
          .to raise_error(Git::FailedError, /config/)
      end
    end

    context 'when called with name and value' do
      it 'sets the value and a subsequent get returns the new value' do
        described_instance.config('user.name', 'NewName')
        expect(described_instance.config('user.name')).to eq('NewName')
      end

      it 'returns a Git::CommandLineResult' do
        result = described_instance.config('user.name', 'NewName')
        expect(result).to be_a(Git::CommandLineResult)
      end

      context 'with the file: option pointing to a custom config file' do
        let(:custom_config_path) { File.join(repo_dir, 'custom.config') }

        it 'writes the value to the custom file' do
          described_instance.config('user.name', 'CustomName', file: custom_config_path)
          config_content = File.read(custom_config_path)
          expect(config_content).to include('CustomName')
        end

        it 'does not modify the default .git/config for the written key' do
          expect do
            described_instance.config('user.name', 'CustomName', file: custom_config_path)
          end.not_to(change { described_instance.config('user.name') })
        end
      end
    end
  end
end
