# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/list'
require 'git/parsers/stash'

RSpec.describe Git::Commands::Stash::List do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options' do
      it 'runs stash list with the stash format' do
        format_arg = "--format=#{Git::Parsers::Stash::STASH_FORMAT}"
        expected_result = command_result('stash output')

        expect_command_capturing('stash', 'list', format_arg)
          .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(foo: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
