# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/reset'

RSpec.describe Git::Commands::Reset do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git reset without a commit and returns the result' do
        expected_result = command_result
        expect_command_capturing('reset').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a commit argument' do
      it 'resets to the specified commit' do
        expect_command_capturing('reset', 'HEAD~1').and_return(command_result)

        command.call('HEAD~1')
      end

      it 'resets to a SHA' do
        expect_command_capturing('reset', 'abc123').and_return(command_result)

        command.call('abc123')
      end

      it 'accepts nil as the commit' do
        expect_command_capturing('reset').and_return(command_result)

        command.call(nil)
      end
    end

    context 'with the :soft option' do
      it 'adds --soft to the command line' do
        expect_command_capturing('reset', '--soft').and_return(command_result)

        command.call(soft: true)
      end

      it 'adds --soft before the commit' do
        expect_command_capturing('reset', '--soft', 'HEAD~1').and_return(command_result)

        command.call('HEAD~1', soft: true)
      end

      it 'does not include the flag when false' do
        expect_command_capturing('reset').and_return(command_result)

        command.call(soft: false)
      end
    end

    context 'with the :mixed option' do
      it 'adds --mixed to the command line' do
        expect_command_capturing('reset', '--mixed').and_return(command_result)

        command.call(mixed: true)
      end

      it 'adds --mixed before the commit' do
        expect_command_capturing('reset', '--mixed', 'HEAD~1').and_return(command_result)

        command.call('HEAD~1', mixed: true)
      end

      it 'does not include the flag when false' do
        expect_command_capturing('reset').and_return(command_result)

        command.call(mixed: false)
      end
    end

    context 'with the :N option' do
      it 'adds -N to the command line' do
        expect_command_capturing('reset', '-N').and_return(command_result)

        command.call(N: true)
      end
    end

    context 'with the :hard option' do
      it 'adds --hard to the command line' do
        expect_command_capturing('reset', '--hard').and_return(command_result)

        command.call(hard: true)
      end

      it 'adds --hard before the commit' do
        expect_command_capturing('reset', '--hard', 'HEAD~1').and_return(command_result)

        command.call('HEAD~1', hard: true)
      end

      it 'does not include the flag when false' do
        expect_command_capturing('reset').and_return(command_result)

        command.call(hard: false)
      end
    end

    context 'with the :merge option' do
      it 'adds --merge to the command line' do
        expect_command_capturing('reset', '--merge').and_return(command_result)

        command.call(merge: true)
      end
    end

    context 'with the :keep option' do
      it 'adds --keep to the command line' do
        expect_command_capturing('reset', '--keep').and_return(command_result)

        command.call(keep: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet when true' do
        expect_command_capturing('reset', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('reset', '--quiet').and_return(command_result)

        command.call(q: true)
      end

      context 'when :no_quiet is true' do
        it 'adds --no-quiet to the command line' do
          expect_command_capturing('reset', '--no-quiet').and_return(command_result)

          command.call(no_quiet: true)
        end
      end
    end

    context 'with the :refresh option' do
      it 'adds --refresh when true' do
        expect_command_capturing('reset', '--refresh').and_return(command_result)

        command.call(refresh: true)
      end

      context 'when :no_refresh is true' do
        it 'adds --no-refresh to the command line' do
          expect_command_capturing('reset', '--no-refresh').and_return(command_result)

          command.call(no_refresh: true)
        end
      end
    end

    context 'with the :unified option' do
      it 'adds --unified=<n> to the command line' do
        expect_command_capturing('reset', '--unified=3').and_return(command_result)

        command.call(unified: 3)
      end

      it 'supports the :U alias' do
        expect_command_capturing('reset', '--unified=3').and_return(command_result)

        command.call(U: 3)
      end
    end

    context 'with the :inter_hunk_context option' do
      it 'adds --inter-hunk-context=<n> to the command line' do
        expect_command_capturing('reset', '--inter-hunk-context=5').and_return(command_result)

        command.call(inter_hunk_context: 5)
      end
    end

    context 'with the :pathspec_from_file option' do
      it 'adds --pathspec-from-file=<file> to the command line' do
        expect_command_capturing('reset', '--pathspec-from-file=paths.txt').and_return(command_result)

        command.call(pathspec_from_file: 'paths.txt')
      end

      it 'accepts "-" to read from standard input' do
        expect_command_capturing('reset', '--pathspec-from-file=-').and_return(command_result)

        command.call(pathspec_from_file: '-')
      end
    end

    context 'with the :pathspec_file_nul option' do
      it 'adds --pathspec-file-nul to the command line' do
        expect_command_capturing('reset', '--pathspec-file-nul').and_return(command_result)

        command.call(pathspec_file_nul: true)
      end
    end

    context 'with the :recurse_submodules option' do
      it 'adds --recurse-submodules when true' do
        expect_command_capturing('reset', '--recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: true)
      end

      context 'when :no_recurse_submodules is true' do
        it 'adds --no-recurse-submodules to the command line' do
          expect_command_capturing('reset', '--no-recurse-submodules').and_return(command_result)

          command.call(no_recurse_submodules: true)
        end
      end
    end

    context 'with the :pathspec option' do
      it 'adds -- and the pathspec entries' do
        expect_command_capturing('reset', '--', 'file.rb').and_return(command_result)

        command.call(pathspec: ['file.rb'])
      end

      it 'supports multiple pathspec entries' do
        expect_command_capturing('reset', '--', 'file.rb', 'dir/').and_return(command_result)

        command.call(pathspec: ['file.rb', 'dir/'])
      end

      it 'places commit before -- and pathspec after' do
        expect_command_capturing('reset', 'HEAD~1', '--', 'file.rb').and_return(command_result)

        command.call('HEAD~1', pathspec: ['file.rb'])
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
