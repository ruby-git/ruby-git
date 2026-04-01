# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/archive/list_formats'

RSpec.describe Git::Commands::Archive::ListFormats, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with output' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end
    end
  end
end
