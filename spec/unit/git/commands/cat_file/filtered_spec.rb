# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/filtered'

RSpec.describe Git::Commands::CatFile::Filtered do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#initialize' do
    it 'accepts an execution context' do
      expect { described_class.new(execution_context) }.not_to raise_error
    end
  end

  describe '#call' do
    context 'with --textconv mode' do
      it 'passes --textconv and the combined rev:path and returns the result' do
        expected_result = command_result('file content')
        expect_command_capturing('cat-file', '--textconv', '--', 'HEAD:README.md').and_return(expected_result)

        result = command.call('HEAD:README.md', textconv: true)

        expect(result).to eq(expected_result)
      end
    end

    context 'with --filters mode' do
      it 'passes --filters and the combined rev:path' do
        expect_command_capturing('cat-file', '--filters', '--', 'HEAD:README.md').and_return(command_result('content'))

        command.call('HEAD:README.md', filters: true)
      end
    end

    context 'with --path= option' do
      it 'passes --path= inline and the bare revision separately' do
        expect_command_capturing('cat-file', '--textconv', '--path=README.md', '--', 'HEAD')
          .and_return(command_result('content'))

        command.call('HEAD', textconv: true, path: 'README.md')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for an unsupported option' do
        expect { command.call('HEAD:file.txt', bogus: true) }
          .to raise_error(ArgumentError, /bogus|Unsupported options/)
      end
    end
  end
end
