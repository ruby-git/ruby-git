# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/set'
require 'git/commands/config_option_syntax/get'

RSpec.describe Git::Commands::ConfigOptionSyntax::Set, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('test.key', 'test-value')

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when the key has no section' do
        expect { command.call('invalid', 'value') }.to raise_error(Git::FailedError, /does not contain a section/)
      end
    end
  end
end
