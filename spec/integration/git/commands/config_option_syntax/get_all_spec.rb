# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_all'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetAll, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('user.name')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns the configured value in stdout' do
        result = command.call('user.name', local: true)

        expect(result.stdout.strip).to eq('Test User')
      end

      it 'returns result with exit status 1 when the key is not found' do
        result = command.call('nonexistent.key')

        expect(result.status.exitstatus).to eq(1)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when given a malformed config file' do
        malformed_config = File.join(repo_dir, 'malformed.config')
        File.write(malformed_config, "[incomplete-section\n")

        expect { command.call('user.name', file: malformed_config) }
          .to raise_error(Git::FailedError, /malformed\.config/)
      end
    end
  end
end
