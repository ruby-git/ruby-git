# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/rm'

RSpec.describe Git::Commands::Rm do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git rm with no options or pathspecs' do
        expected_result = command_result
        expect_command_capturing('rm').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a single pathspec' do
      it 'adds -- and the pathspec' do
        expect_command_capturing('rm', '--', 'file.txt').and_return(command_result)

        command.call('file.txt')
      end
    end

    context 'with multiple pathspecs' do
      it 'adds -- and all pathspecs' do
        expect_command_capturing('rm', '--', 'file1.txt', 'file2.txt').and_return(command_result)

        command.call('file1.txt', 'file2.txt')
      end
    end

    context 'with the :force option' do
      it 'adds --force to the command line' do
        expect_command_capturing('rm', '--force', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', force: true)
      end

      it 'supports the :f alias' do
        expect_command_capturing('rm', '--force', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', f: true)
      end
    end

    context 'with the :dry_run option' do
      it 'adds --dry-run to the command line' do
        expect_command_capturing('rm', '--dry-run', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', dry_run: true)
      end

      it 'supports the :n alias' do
        expect_command_capturing('rm', '--dry-run', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', n: true)
      end
    end

    context 'with the :r option' do
      it 'adds -r to the command line' do
        expect_command_capturing('rm', '-r', '--', 'directory/').and_return(command_result)

        command.call('directory/', r: true)
      end
    end

    context 'with the :cached option' do
      it 'adds --cached to the command line' do
        expect_command_capturing('rm', '--cached', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', cached: true)
      end
    end

    context 'with the :ignore_unmatch option' do
      it 'adds --ignore-unmatch to the command line' do
        expect_command_capturing('rm', '--ignore-unmatch', '--', '*.txt').and_return(command_result)

        command.call('*.txt', ignore_unmatch: true)
      end
    end

    context 'with the :sparse option' do
      it 'adds --sparse to the command line' do
        expect_command_capturing('rm', '--sparse', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', sparse: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('rm', '--quiet', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('rm', '--quiet', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', q: true)
      end
    end

    context 'with the :pathspec_from_file option' do
      it 'adds --pathspec-from-file=<file> to the command line' do
        expect_command_capturing('rm', '--pathspec-from-file=paths.txt').and_return(command_result)

        command.call(pathspec_from_file: 'paths.txt')
      end
    end

    context 'with the :pathspec_file_nul option' do
      it 'adds --pathspec-file-nul to the command line' do
        expect_command_capturing(
          'rm', '--pathspec-from-file=paths.txt', '--pathspec-file-nul'
        ).and_return(command_result)

        command.call(pathspec_from_file: 'paths.txt', pathspec_file_nul: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('file.txt', invalid: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
