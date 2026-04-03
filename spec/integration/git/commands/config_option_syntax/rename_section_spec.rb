# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/rename_section'

RSpec.describe Git::Commands::ConfigOptionSyntax::RenameSection, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        repo.config('oldsection.key', 'value')
      end

      it 'returns a CommandLineResult' do
        result = command.call('oldsection', 'newsection')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns result with exit status 0' do
        result = command.call('oldsection', 'newsection')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'renames the section' do
        command.call('oldsection', 'newsection')

        expect(repo.config('newsection.key')).to eq('value')
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent section' do
        expect { command.call('nonexistent', 'newsection') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end
    end
  end
end
