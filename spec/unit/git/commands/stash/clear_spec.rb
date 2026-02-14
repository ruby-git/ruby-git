# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/clear'

RSpec.describe Git::Commands::Stash::Clear do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    it 'calls git stash clear' do
      expected_result = command_result
      expect(execution_context).to receive(:command).with('stash', 'clear')
                                                    .and_return(expected_result)

      result = command.call

      expect(result).to eq(expected_result)
    end
  end
end
