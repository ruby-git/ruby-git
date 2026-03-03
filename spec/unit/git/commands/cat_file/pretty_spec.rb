# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/pretty'

RSpec.describe Git::Commands::CatFile::Pretty do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with an object argument' do
      it 'runs git cat-file -p with the object' do
        expected_result = command_result('')
        expect_command_with_capture('cat-file', '-p', 'HEAD').and_return(expected_result)
        result = command.call('HEAD')
        expect(result).to eq(expected_result)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when object is missing' do
        expect { command.call }.to raise_error(ArgumentError, 'object is required')
      end
    end
  end
end
