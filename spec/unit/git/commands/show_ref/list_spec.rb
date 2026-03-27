# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show_ref/list'

RSpec.describe Git::Commands::ShowRef::List do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git show-ref with no flags' do
        expected_result = command_result
        expect_command_capturing('show-ref').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a single pattern operand' do
      it 'appends -- and the pattern' do
        expect_command_capturing('show-ref', '--', 'refs/tags/v1.0').and_return(command_result)

        command.call('refs/tags/v1.0')
      end
    end

    context 'with multiple pattern operands' do
      it 'appends -- and all patterns' do
        expect_command_capturing('show-ref', '--', 'refs/tags/v1.0', 'refs/heads/main').and_return(command_result)

        command.call('refs/tags/v1.0', 'refs/heads/main')
      end
    end

    context 'with the :head option' do
      it 'adds --head' do
        expect_command_capturing('show-ref', '--head').and_return(command_result)

        command.call(head: true)
      end
    end

    context 'with the :heads option' do
      it 'adds --heads' do
        expect_command_capturing('show-ref', '--heads').and_return(command_result)

        command.call(heads: true)
      end
    end

    context 'with the :tags option' do
      it 'adds --tags' do
        expect_command_capturing('show-ref', '--tags').and_return(command_result)

        command.call(tags: true)
      end
    end

    context 'with the :dereference option' do
      it 'adds --dereference' do
        expect_command_capturing('show-ref', '--dereference').and_return(command_result)

        command.call(dereference: true)
      end
    end

    context 'with the :d alias for :dereference' do
      it 'adds --dereference' do
        expect_command_capturing('show-ref', '--dereference').and_return(command_result)

        command.call(d: true)
      end
    end

    context 'with :hash set to true' do
      it 'adds --hash without a value' do
        expect_command_capturing('show-ref', '--hash').and_return(command_result)

        command.call(hash: true)
      end
    end

    context 'with :hash set to an integer' do
      it 'adds --hash=<n> inline' do
        expect_command_capturing('show-ref', '--hash=7').and_return(command_result)

        command.call(hash: 7)
      end
    end

    context 'with the :s alias for :hash' do
      it 'adds --hash' do
        expect_command_capturing('show-ref', '--hash').and_return(command_result)

        command.call(s: true)
      end
    end

    context 'with :abbrev set to true' do
      it 'adds --abbrev without a value' do
        expect_command_capturing('show-ref', '--abbrev').and_return(command_result)

        command.call(abbrev: true)
      end
    end

    context 'with :abbrev set to an integer' do
      it 'adds --abbrev=<n> inline' do
        expect_command_capturing('show-ref', '--abbrev=7').and_return(command_result)

        command.call(abbrev: 7)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect_command_capturing('show-ref', timeout: 5).and_return(command_result)

        command.call(timeout: 5)
      end
    end

    context 'with combined options and a pattern' do
      it 'emits flags before -- and pattern after' do
        expect_command_capturing('show-ref', '--hash', '--tags', '--', 'v1.0').and_return(command_result)

        command.call('v1.0', tags: true, hash: true)
      end
    end

    context 'exit code handling' do
      it 'returns normally on exit status 0' do
        expect_command_capturing('show-ref').and_return(command_result(exitstatus: 0))

        result = command.call

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns normally on exit status 1 (no matching refs)' do
        expect_command_capturing('show-ref', '--', 'nonexistent').and_return(
          command_result('', exitstatus: 1)
        )

        result = command.call('nonexistent')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises Git::FailedError on exit status 2' do
        expect_command_capturing('show-ref').and_return(command_result(exitstatus: 2))

        expect { command.call }.to raise_error(Git::FailedError, /git/)
      end

      it 'raises Git::FailedError on exit status 128' do
        expect_command_capturing('show-ref').and_return(command_result(exitstatus: 128))

        expect { command.call }.to raise_error(Git::FailedError, /git/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(bogus: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
