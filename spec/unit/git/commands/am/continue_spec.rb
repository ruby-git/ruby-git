# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/am/continue'

RSpec.describe Git::Commands::Am::Continue do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    it 'calls git am --continue' do
      expected_result = command_result('')
      expect_command_capturing('am', '--continue').and_return(expected_result)

      result = command.call

      expect(result).to eq(expected_result)
    end
  end
end
