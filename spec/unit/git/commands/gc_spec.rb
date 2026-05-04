# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/gc'

RSpec.describe Git::Commands::Gc do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options' do
      it 'runs git gc with no extra arguments' do
        expected_result = command_result
        expect_command_capturing('gc').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :aggressive option' do
      it 'adds --aggressive when true' do
        expect_command_capturing('gc', '--aggressive').and_return(command_result)

        command.call(aggressive: true)
      end
    end

    context 'with the :auto option' do
      it 'adds --auto when true' do
        expect_command_capturing('gc', '--auto').and_return(command_result)

        command.call(auto: true)
      end
    end

    context 'with :prune option as true' do
      it 'passes --prune' do
        expect_command_capturing('gc', '--prune').and_return(command_result)

        command.call(prune: true)
      end
    end

    context 'with :prune option as a date string' do
      it 'passes --prune=<date>' do
        expect_command_capturing('gc', '--prune=now').and_return(command_result)

        command.call(prune: 'now')
      end
    end

    context 'with :prune option' do
      context 'when :no_prune is true' do
        it 'passes --no-prune' do
          expect_command_capturing('gc', '--no-prune').and_return(command_result)

          command.call(no_prune: true)
        end
      end
    end

    context 'with the :detach option' do
      context 'when true' do
        it 'adds --detach flag' do
          expect_command_capturing('gc', '--detach').and_return(command_result)

          command.call(detach: true)
        end
      end

      context 'when :no_detach is true' do
        it 'adds --no-detach flag' do
          expect_command_capturing('gc', '--no-detach').and_return(command_result)

          command.call(no_detach: true)
        end
      end
    end

    context 'with the :cruft option' do
      context 'when true' do
        it 'adds --cruft flag' do
          expect_command_capturing('gc', '--cruft').and_return(command_result)

          command.call(cruft: true)
        end
      end

      context 'when :no_cruft is true' do
        it 'adds --no-cruft flag' do
          expect_command_capturing('gc', '--no-cruft').and_return(command_result)

          command.call(no_cruft: true)
        end
      end
    end

    context 'with the :max_cruft_size option' do
      it 'passes --max-cruft-size=<n>' do
        expect_command_capturing('gc', '--max-cruft-size=1g').and_return(command_result)

        command.call(max_cruft_size: '1g')
      end
    end

    context 'with the :expire_to option' do
      it 'passes --expire-to=<dir>' do
        expect_command_capturing('gc', '--expire-to=/tmp/pruned').and_return(command_result)

        command.call(expire_to: '/tmp/pruned')
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet when true' do
        expect_command_capturing('gc', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end
    end

    context 'with the :force option' do
      it 'adds --force when true' do
        expect_command_capturing('gc', '--force').and_return(command_result)

        command.call(force: true)
      end
    end

    context 'with the :keep_largest_pack option' do
      it 'adds --keep-largest-pack when true' do
        expect_command_capturing('gc', '--keep-largest-pack').and_return(command_result)

        command.call(keep_largest_pack: true)
      end
    end

    context 'with :aggressive, :quiet, and :prune combined' do
      it 'passes all three flags in DSL-defined order' do
        expect_command_capturing('gc', '--aggressive', '--prune=now', '--quiet').and_return(command_result)

        command.call(aggressive: true, prune: 'now', quiet: true)
      end
    end

    context 'with :auto and :quiet combined' do
      it 'passes both flags in DSL-defined order' do
        expect_command_capturing('gc', '--auto', '--quiet').and_return(command_result)

        command.call(auto: true, quiet: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
