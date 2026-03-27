# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show_ref/verify'

RSpec.describe Git::Commands::ShowRef::Verify do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single full ref name' do
      it 'runs git show-ref --verify -- <ref>' do
        expected_result = command_result
        expect_command_capturing('show-ref', '--verify', '--', 'refs/heads/main')
          .and_return(expected_result)

        result = command.call('refs/heads/main')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple full ref names' do
      it 'appends all refs after --' do
        expect_command_capturing('show-ref', '--verify', '--', 'refs/heads/main', 'refs/tags/v1.0')
          .and_return(command_result)

        command.call('refs/heads/main', 'refs/tags/v1.0')
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet' do
        expect_command_capturing('show-ref', '--verify', '--quiet', '--', 'refs/heads/main')
          .and_return(command_result)

        command.call('refs/heads/main', quiet: true)
      end
    end

    context 'with the :q alias for :quiet' do
      it 'adds --quiet' do
        expect_command_capturing('show-ref', '--verify', '--quiet', '--', 'refs/heads/main')
          .and_return(command_result)

        command.call('refs/heads/main', q: true)
      end
    end

    context 'with the :dereference option' do
      it 'adds --dereference' do
        expect_command_capturing('show-ref', '--verify', '--dereference', '--', 'refs/tags/v1.0')
          .and_return(command_result)

        command.call('refs/tags/v1.0', dereference: true)
      end
    end

    context 'with the :d alias for :dereference' do
      it 'adds --dereference' do
        expect_command_capturing('show-ref', '--verify', '--dereference', '--', 'refs/tags/v1.0')
          .and_return(command_result)

        command.call('refs/tags/v1.0', d: true)
      end
    end

    context 'with :hash set to true' do
      it 'adds --hash without a value' do
        expect_command_capturing('show-ref', '--verify', '--hash', '--', 'refs/heads/main')
          .and_return(command_result)

        command.call('refs/heads/main', hash: true)
      end
    end

    context 'with :hash set to an integer' do
      it 'adds --hash=<n> inline' do
        expect_command_capturing('show-ref', '--verify', '--hash=7', '--', 'refs/heads/main')
          .and_return(command_result)

        command.call('refs/heads/main', hash: 7)
      end
    end

    context 'with the :s alias for :hash' do
      it 'adds --hash' do
        expect_command_capturing('show-ref', '--verify', '--hash', '--', 'refs/heads/main')
          .and_return(command_result)

        command.call('refs/heads/main', s: true)
      end
    end

    context 'with :abbrev set to true' do
      it 'adds --abbrev without a value' do
        expect_command_capturing('show-ref', '--verify', '--abbrev', '--', 'refs/heads/main')
          .and_return(command_result)

        command.call('refs/heads/main', abbrev: true)
      end
    end

    context 'with :abbrev set to an integer' do
      it 'adds --abbrev=<n> inline' do
        expect_command_capturing('show-ref', '--verify', '--abbrev=7', '--', 'refs/heads/main')
          .and_return(command_result)

        command.call('refs/heads/main', abbrev: 7)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect_command_capturing('show-ref', '--verify', '--', 'refs/heads/main', timeout: 5)
          .and_return(command_result)

        command.call('refs/heads/main', timeout: 5)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when no ref names are provided' do
        expect { command.call }.to raise_error(ArgumentError, /ref/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('refs/heads/main', bogus: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
