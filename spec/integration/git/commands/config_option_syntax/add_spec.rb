# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/add'

RSpec.describe Git::Commands::ConfigOptionSyntax::Add, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('test.multi', 'value1')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid config key' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('invalidkey', 'value') }
          .to raise_error(Git::FailedError, /invalidkey/)
      end
    end
  end
end
