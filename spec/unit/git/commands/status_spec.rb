# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/status'

RSpec.describe Git::Commands::Status do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git status without any flags' do
        expected_result = command_result
        expect_command_capturing('status').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :short option' do
      it 'adds --short to the command line' do
        expect_command_capturing('status', '--short').and_return(command_result)

        command.call(short: true)
      end

      it 'accepts :s as an alias' do
        expect_command_capturing('status', '--short').and_return(command_result)

        command.call(s: true)
      end
    end

    context 'with the :branch option' do
      it 'adds --branch to the command line' do
        expect_command_capturing('status', '--branch').and_return(command_result)

        command.call(branch: true)
      end

      it 'accepts :b as an alias' do
        expect_command_capturing('status', '--branch').and_return(command_result)

        command.call(b: true)
      end
    end

    context 'with the :show_stash option' do
      it 'adds --show-stash to the command line' do
        expect_command_capturing('status', '--show-stash').and_return(command_result)

        command.call(show_stash: true)
      end
    end

    context 'with the :long option' do
      it 'adds --long to the command line' do
        expect_command_capturing('status', '--long').and_return(command_result)

        command.call(long: true)
      end
    end

    context 'with the :verbose option' do
      it 'adds --verbose to the command line' do
        expect_command_capturing('status', '--verbose').and_return(command_result)

        command.call(verbose: true)
      end

      it 'accepts :v as an alias' do
        expect_command_capturing('status', '--verbose').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with the :porcelain option' do
      it 'adds --porcelain when given true' do
        expect_command_capturing('status', '--porcelain').and_return(command_result)

        command.call(porcelain: true)
      end

      it 'adds --porcelain=<version> when given a string value' do
        expect_command_capturing('status', '--porcelain=v1').and_return(command_result)

        command.call(porcelain: 'v1')
      end
    end

    context 'with the :untracked_files option' do
      it 'adds --untracked-files when given true' do
        expect_command_capturing('status', '--untracked-files').and_return(command_result)

        command.call(untracked_files: true)
      end

      it 'adds --untracked-files=<mode> when given a string' do
        expect_command_capturing('status', '--untracked-files=all').and_return(command_result)

        command.call(untracked_files: 'all')
      end

      it 'accepts :u as an alias' do
        expect_command_capturing('status', '--untracked-files').and_return(command_result)

        command.call(u: true)
      end
    end

    context 'with the :ignored option' do
      it 'adds --ignored when given true' do
        expect_command_capturing('status', '--ignored').and_return(command_result)

        command.call(ignored: true)
      end

      it 'adds --ignored=<mode> when given a string' do
        expect_command_capturing('status', '--ignored=matching').and_return(command_result)

        command.call(ignored: 'matching')
      end
    end

    context 'with the :ignore_submodules option' do
      it 'adds --ignore-submodules when given true' do
        expect_command_capturing('status', '--ignore-submodules').and_return(command_result)

        command.call(ignore_submodules: true)
      end

      it 'adds --ignore-submodules=<when> when given a string' do
        expect_command_capturing('status', '--ignore-submodules=untracked').and_return(command_result)

        command.call(ignore_submodules: 'untracked')
      end
    end

    context 'with the :column option' do
      it 'adds --column when given true' do
        expect_command_capturing('status', '--column').and_return(command_result)

        command.call(column: true)
      end

      it 'adds --column=<options> when given a string' do
        expect_command_capturing('status', '--column=auto').and_return(command_result)

        command.call(column: 'auto')
      end

      context 'when :no_column is true' do
        it 'adds --no-column' do
          expect_command_capturing('status', '--no-column').and_return(command_result)

          command.call(no_column: true)
        end
      end
    end

    context 'with the :ahead_behind option' do
      it 'adds --ahead-behind when given true' do
        expect_command_capturing('status', '--ahead-behind').and_return(command_result)

        command.call(ahead_behind: true)
      end

      context 'when :no_ahead_behind is true' do
        it 'adds --no-ahead-behind' do
          expect_command_capturing('status', '--no-ahead-behind').and_return(command_result)

          command.call(no_ahead_behind: true)
        end
      end
    end

    context 'with the :renames option' do
      it 'adds --renames when given true' do
        expect_command_capturing('status', '--renames').and_return(command_result)

        command.call(renames: true)
      end

      context 'when :no_renames is true' do
        it 'adds --no-renames' do
          expect_command_capturing('status', '--no-renames').and_return(command_result)

          command.call(no_renames: true)
        end
      end
    end

    context 'with the :find_renames option' do
      it 'adds --find-renames when given true' do
        expect_command_capturing('status', '--find-renames').and_return(command_result)

        command.call(find_renames: true)
      end

      it 'adds --find-renames=<n> when given an integer string' do
        expect_command_capturing('status', '--find-renames=50').and_return(command_result)

        command.call(find_renames: '50')
      end
    end

    context 'with the :z option' do
      it 'adds -z to the command line' do
        expect_command_capturing('status', '-z').and_return(command_result)

        command.call(z: true)
      end
    end

    context 'with pathspec operands' do
      it 'appends paths after -- separator' do
        expect_command_capturing('status', '--', 'lib/').and_return(command_result)

        command.call('lib/')
      end

      it 'appends multiple paths after -- separator' do
        expect_command_capturing('status', '--', 'lib/', 'spec/').and_return(command_result)

        command.call('lib/', 'spec/')
      end

      it 'combines pathspecs with options' do
        expect_command_capturing('status', '--short', '--', 'lib/').and_return(command_result)

        command.call('lib/', short: true)
      end
    end

    context 'input validation' do
      it 'raises an ArgumentError for unexpected options' do
        expect { command.call(unexpected: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :unexpected/)
        )
      end
    end
  end
end
