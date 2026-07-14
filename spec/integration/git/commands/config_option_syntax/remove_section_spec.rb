# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get'
require 'git/commands/config_option_syntax/remove_section'
require 'git/commands/config_option_syntax/set'

RSpec.describe Git::Commands::ConfigOptionSyntax::RemoveSection, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        set = Git::Commands::ConfigOptionSyntax::Set.new(execution_context)
        set.call('testsection.key', 'value')
      end

      it 'returns a CommandLineResult' do
        result = command.call('testsection')

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when the section does not exist' do
        expect { command.call('nonexistent-section') }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
