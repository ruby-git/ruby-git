# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/list'

RSpec.describe Git::Commands::ConfigOptionSyntax::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when the config file does not exist' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call(file: 'nonexistent.conf') }
          .to raise_error(Git::FailedError, /nonexistent\.conf/)
      end
    end
  end
end
