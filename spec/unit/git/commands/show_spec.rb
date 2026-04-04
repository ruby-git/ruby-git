# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show'

RSpec.describe Git::Commands::Show do
  # Duck-type collaborator: command specs depend on the #command_capturing and
  # #command_streaming interfaces, not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git show with no extra arguments and returns the result' do
        expected_result = command_result
        expect_command_capturing('show', chomp: false).and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a single object' do
      it 'passes the object specifier to git show' do
        expect_command_capturing('show', 'HEAD', chomp: false).and_return(command_result)

        command.call('HEAD')
      end
    end

    context 'with an objectish:path expression' do
      it 'passes the combined expression as a single argument' do
        expect_command_capturing('show', 'abc123:README.md', chomp: false).and_return(command_result)

        command.call('abc123:README.md')
      end
    end

    context 'with multiple objects' do
      it 'passes each object specifier as a separate argument' do
        expect_command_capturing('show', 'v1.0', 'v2.0', chomp: false).and_return(command_result)

        command.call('v1.0', 'v2.0')
      end
    end

    context 'with out: execution option (streaming)' do
      it 'dispatches to command_streaming when out: is given' do
        out_io = instance_double(File)
        expect_command_streaming('show', ':2:path/to/file.txt', out: out_io).and_return(command_result)

        command.call(':2:path/to/file.txt', out: out_io)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(foo: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
