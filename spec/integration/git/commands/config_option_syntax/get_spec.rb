# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get'

RSpec.describe Git::Commands::ConfigOptionSyntax::Get, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('user.name')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit code 0 when the key exists' do
        result = command.call('user.name')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit code 1 when the key is not found' do
        result = command.call('nonexistent.key')

        expect(result.status.exitstatus).to eq(1)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid type argument' do
        expect { command.call('user.name', type: 'invalid_type') }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
