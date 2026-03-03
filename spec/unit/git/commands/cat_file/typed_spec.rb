# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/typed'

RSpec.describe Git::Commands::CatFile::Typed do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with type and object arguments' do
      it 'runs git cat-file with type then object' do
        expected_result = command_result('')
        expect_command('cat-file', 'commit', 'HEAD').and_return(expected_result)
        result = command.call('commit', 'HEAD')
        expect(result).to eq(expected_result)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when type is missing' do
        expect { command.call }.to raise_error(ArgumentError, 'type is required')
      end

      it 'raises ArgumentError when object is missing' do
        expect { command.call('commit') }.to raise_error(ArgumentError, 'object is required')
      end
    end
  end
end
