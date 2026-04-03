# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/replace_all'

RSpec.describe Git::Commands::ConfigOptionSyntax::ReplaceAll, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        execution_context.command_capturing('config', '--add', 'test.multi', 'old1')
        execution_context.command_capturing('config', '--add', 'test.multi', 'old2')
      end

      it 'returns a CommandLineResult' do
        result = command.call('test.multi', 'new-value')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid key name' do
        expect { command.call('invalidkey', 'value') }
          .to raise_error(Git::FailedError, /invalidkey/)
      end
    end
  end
end
