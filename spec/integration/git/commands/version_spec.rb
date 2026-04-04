# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/version'

RSpec.describe Git::Commands::Version, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to match(/\Agit version \d+\.\d+/)
        expect(result.stderr).to be_empty
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unsupported: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
