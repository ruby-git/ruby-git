# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/add'
require 'git/commands/config_option_syntax/unset_all'

RSpec.describe Git::Commands::ConfigOptionSyntax::UnsetAll, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        add = Git::Commands::ConfigOptionSyntax::Add.new(execution_context)
        add.call('test.multi', 'value1')
        add.call('test.multi', 'value2')
      end

      it 'returns a CommandLineResult' do
        result = command.call('test.multi')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit status 0 when the key exists' do
        result = command.call('test.multi')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 5 when the key does not exist' do
        result = command.call('nonexistent.key')

        expect(result.status.exitstatus).to eq(5)
      end
    end

    context 'when the command fails' do
      before { FileUtils.rm_rf(File.join(repo_dir, '.git')) }

      it 'raises FailedError outside a git repository' do
        expect { command.call('test.key') }
          .to raise_error(Git::FailedError, /test\.key/)
      end
    end
  end
end
