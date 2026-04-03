# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/unset'
require 'git/commands/config_option_syntax/set'
require 'git/commands/config_option_syntax/get'

RSpec.describe Git::Commands::ConfigOptionSyntax::Unset, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        set = Git::Commands::ConfigOptionSyntax::Set.new(execution_context)
        set.call('test.key', 'test-value')
      end

      it 'returns a CommandLineResult' do
        result = command.call('test.key')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns result with exit status 0' do
        result = command.call('test.key')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'removes the config entry' do
        command.call('test.key')

        get = Git::Commands::ConfigOptionSyntax::Get.new(execution_context)
        result = get.call('test.key')
        expect(result.status.exitstatus).to eq(1)
      end

      it 'returns exit status 5 when the key does not exist' do
        result = command.call('nonexistent.key')

        expect(result.status.exitstatus).to eq(5)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError outside a git repository' do
        execution_context # ensure repo is initialized before removing .git
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call('test.key') }.to raise_error(Git::FailedError, /test\.key/)
      end
    end
  end
end
