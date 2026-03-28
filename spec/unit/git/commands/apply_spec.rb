# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/apply'

RSpec.describe Git::Commands::Apply do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no patch files' do
      it 'calls git apply with no arguments' do
        expected_result = command_result
        expect_command_capturing('apply').and_return(expected_result)
        result = command.call
        expect(result).to eq(expected_result)
      end
    end

    context 'with a single patch file' do
      it 'calls git apply with end-of-options separator and the patch file' do
        expect_command_capturing('apply', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch')
      end
    end

    context 'with multiple patch files' do
      it 'calls git apply with all patch files after --' do
        expect_command_capturing('apply', '--', 'a.patch', 'b.patch').and_return(command_result)
        command.call('a.patch', 'b.patch')
      end
    end

    context 'with :stat option' do
      it 'adds --stat flag' do
        expect_command_capturing('apply', '--stat', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', stat: true)
      end
    end

    context 'with :numstat option' do
      it 'adds --numstat flag' do
        expect_command_capturing('apply', '--numstat', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', numstat: true)
      end
    end

    context 'with :summary option' do
      it 'adds --summary flag' do
        expect_command_capturing('apply', '--summary', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', summary: true)
      end
    end

    context 'with :check option' do
      it 'adds --check flag' do
        expect_command_capturing('apply', '--check', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', check: true)
      end
    end

    context 'with :index option' do
      it 'adds --index flag' do
        expect_command_capturing('apply', '--index', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', index: true)
      end
    end

    context 'with :intent_to_add option' do
      it 'adds --intent-to-add flag' do
        expect_command_capturing('apply', '--intent-to-add', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', intent_to_add: true)
      end

      it 'accepts :N alias' do
        expect_command_capturing('apply', '--intent-to-add', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', N: true)
      end
    end

    context 'with :three_way option' do
      it 'adds --3way flag' do
        expect_command_capturing('apply', '--3way', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', three_way: true)
      end
    end

    context 'with :ours option' do
      it 'adds --ours flag' do
        expect_command_capturing('apply', '--ours', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', ours: true)
      end
    end

    context 'with :theirs option' do
      it 'adds --theirs flag' do
        expect_command_capturing('apply', '--theirs', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', theirs: true)
      end
    end

    context 'with :union option' do
      it 'adds --union flag' do
        expect_command_capturing('apply', '--union', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', union: true)
      end
    end

    context 'with :apply option' do
      it 'adds --apply flag' do
        expect_command_capturing('apply', '--apply', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', apply: true)
      end
    end

    context 'with :no_add option' do
      it 'adds --no-add flag' do
        expect_command_capturing('apply', '--no-add', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', no_add: true)
      end
    end

    context 'with :build_fake_ancestor option' do
      it 'adds --build-fake-ancestor=<file> inline' do
        expect_command_capturing('apply', '--build-fake-ancestor=ancestor.idx', '--',
                                 'fix.patch').and_return(command_result)
        command.call('fix.patch', build_fake_ancestor: 'ancestor.idx')
      end
    end

    context 'with :reverse option' do
      it 'adds --reverse flag' do
        expect_command_capturing('apply', '--reverse', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', reverse: true)
      end

      it 'accepts :R alias' do
        expect_command_capturing('apply', '--reverse', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', R: true)
      end
    end

    context 'with :allow_binary_replacement option' do
      it 'adds --allow-binary-replacement flag' do
        expect_command_capturing('apply', '--allow-binary-replacement', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', allow_binary_replacement: true)
      end

      it 'accepts :binary alias' do
        expect_command_capturing('apply', '--allow-binary-replacement', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', binary: true)
      end
    end

    context 'with :reject option' do
      it 'adds --reject flag' do
        expect_command_capturing('apply', '--reject', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', reject: true)
      end
    end

    context 'with :z option' do
      it 'adds -z flag' do
        expect_command_capturing('apply', '-z', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', z: true)
      end
    end

    context 'with :p option' do
      it 'adds -p<n> inline' do
        expect_command_capturing('apply', '-p2', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', p: 2)
      end
    end

    context 'with :C option' do
      it 'adds -C<n> inline' do
        expect_command_capturing('apply', '-C3', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', C: 3)
      end
    end

    context 'with :unidiff_zero option' do
      it 'adds --unidiff-zero flag' do
        expect_command_capturing('apply', '--unidiff-zero', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', unidiff_zero: true)
      end
    end

    context 'with :inaccurate_eof option' do
      it 'adds --inaccurate-eof flag' do
        expect_command_capturing('apply', '--inaccurate-eof', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', inaccurate_eof: true)
      end
    end

    context 'with :recount option' do
      it 'adds --recount flag' do
        expect_command_capturing('apply', '--recount', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', recount: true)
      end
    end

    context 'with :cached option' do
      it 'adds --cached flag' do
        expect_command_capturing('apply', '--cached', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', cached: true)
      end
    end

    context 'with :ignore_space_change option' do
      it 'adds --ignore-space-change flag' do
        expect_command_capturing('apply', '--ignore-space-change', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', ignore_space_change: true)
      end
    end

    context 'with :ignore_whitespace option' do
      it 'adds --ignore-whitespace flag' do
        expect_command_capturing('apply', '--ignore-whitespace', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', ignore_whitespace: true)
      end
    end

    context 'with :whitespace option' do
      it 'adds --whitespace=<action> inline' do
        expect_command_capturing('apply', '--whitespace=fix', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', whitespace: 'fix')
      end
    end

    context 'with :exclude option' do
      it 'adds --exclude=<path-pattern> inline' do
        expect_command_capturing('apply', '--exclude=*.txt', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', exclude: '*.txt')
      end
    end

    context 'with :include option' do
      it 'adds --include=<path-pattern> inline' do
        expect_command_capturing('apply', '--include=*.rb', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', include: '*.rb')
      end
    end

    context 'with :directory option' do
      it 'adds --directory=<root> inline' do
        expect_command_capturing('apply', '--directory=src', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', directory: 'src')
      end
    end

    context 'with :verbose option' do
      it 'adds --verbose flag' do
        expect_command_capturing('apply', '--verbose', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', verbose: true)
      end

      it 'accepts :v alias' do
        expect_command_capturing('apply', '--verbose', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', v: true)
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect_command_capturing('apply', '--quiet', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', quiet: true)
      end

      it 'accepts :q alias' do
        expect_command_capturing('apply', '--quiet', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', q: true)
      end
    end

    context 'with :unsafe_paths option' do
      it 'adds --unsafe-paths flag' do
        expect_command_capturing('apply', '--unsafe-paths', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', unsafe_paths: true)
      end
    end

    context 'with :allow_empty option' do
      it 'adds --allow-empty flag' do
        expect_command_capturing('apply', '--allow-empty', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', allow_empty: true)
      end
    end

    context 'with :chdir execution option' do
      it 'passes chdir to the execution context but not to the git CLI' do
        expect_command_capturing('apply', '--', 'fix.patch', chdir: '/some/dir').and_return(command_result)
        command.call('fix.patch', chdir: '/some/dir')
      end
    end

    context 'with multiple options' do
      it 'combines flags in definition order' do
        expect_command_capturing('apply', '--check', '--reverse', '--', 'fix.patch').and_return(command_result)
        command.call('fix.patch', check: true, reverse: true)
      end
    end
  end
end
