# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff_files'

RSpec.describe Git::Commands::DiffFiles do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git diff-files with no options' do
        expected_result = command_result('')
        expect_command_capturing('diff-files').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with diff-files-specific options' do
      it 'includes -q when q: true' do
        expect_command_capturing('diff-files', '-q').and_return(command_result(''))

        command.call(q: true)
      end

      it 'includes -0 when unmerged: true' do
        expect_command_capturing('diff-files', '-0').and_return(command_result(''))

        command.call(unmerged: true)
      end

      it 'includes --base when base: true' do
        expect_command_capturing('diff-files', '--base').and_return(command_result(''))

        command.call(base: true)
      end

      it 'includes --ours when ours: true' do
        expect_command_capturing('diff-files', '--ours').and_return(command_result(''))

        command.call(ours: true)
      end

      it 'includes --theirs when theirs: true' do
        expect_command_capturing('diff-files', '--theirs').and_return(command_result(''))

        command.call(theirs: true)
      end

      it 'includes -c when c: true' do
        expect_command_capturing('diff-files', '-c').and_return(command_result(''))

        command.call(c: true)
      end

      it 'includes --cc when cc: true' do
        expect_command_capturing('diff-files', '--cc').and_return(command_result(''))

        command.call(cc: true)
      end
    end

    context 'with shared diff options' do
      it 'includes --patch when patch: true' do
        expect_command_capturing('diff-files', '--patch').and_return(command_result(''))

        command.call(patch: true)
      end

      it 'adds --unified=3 when unified: 3' do
        expect_command_capturing('diff-files', '--unified=3').and_return(command_result(''))

        command.call(unified: 3)
      end

      it 'includes --stat when stat: true' do
        expect_command_capturing('diff-files', '--stat').and_return(command_result(''))

        command.call(stat: true)
      end

      it 'passes an inline value to --stat= when stat: is a string' do
        expect_command_capturing('diff-files', '--stat=80,40').and_return(command_result(''))

        command.call(stat: '80,40')
      end

      it 'adds --indent-heuristic when indent_heuristic: true' do
        expect_command_capturing('diff-files', '--indent-heuristic').and_return(command_result(''))

        command.call(indent_heuristic: true)
      end

      it 'adds --no-indent-heuristic when indent_heuristic: false' do
        expect_command_capturing('diff-files', '--no-indent-heuristic').and_return(command_result(''))

        command.call(indent_heuristic: false)
      end

      it 'repeats --anchored= for each value in an array' do
        expect_command_capturing('diff-files', '--anchored=ctx1', '--anchored=ctx2').and_return(command_result(''))

        command.call(anchored: %w[ctx1 ctx2])
      end

      it 'supports :M as alias for :find_renames' do
        expect_command_capturing('diff-files', '--find-renames').and_return(command_result(''))

        command.call(M: true)
      end

      it 'includes --color when color: true' do
        expect_command_capturing('diff-files', '--color').and_return(command_result(''))

        command.call(color: true)
      end

      it 'includes --no-color when color: false' do
        expect_command_capturing('diff-files', '--no-color').and_return(command_result(''))

        command.call(color: false)
      end

      it 'includes --color=auto when color: "auto"' do
        expect_command_capturing('diff-files', '--color=auto').and_return(command_result(''))

        command.call(color: 'auto')
      end

      # RF-1: output format aliases
      it 'supports :p as alias for :patch' do
        expect_command_capturing('diff-files', '--patch').and_return(command_result(''))

        command.call(p: true)
      end

      it 'supports :u as alias for :patch' do
        expect_command_capturing('diff-files', '--patch').and_return(command_result(''))

        command.call(u: true)
      end

      it 'supports :U as alias for :unified' do
        expect_command_capturing('diff-files', '--unified=5').and_return(command_result(''))

        command.call(U: '5')
      end

      it 'includes --no-patch when no_patch: true' do
        expect_command_capturing('diff-files', '--no-patch').and_return(command_result(''))

        command.call(no_patch: true)
      end

      it 'supports :s as alias for :no_patch' do
        expect_command_capturing('diff-files', '--no-patch').and_return(command_result(''))

        command.call(s: true)
      end

      # RF-1: whitespace handling aliases
      it 'includes --ignore-space-change when ignore_space_change: true' do
        expect_command_capturing('diff-files', '--ignore-space-change').and_return(command_result(''))

        command.call(ignore_space_change: true)
      end

      it 'supports :b as alias for :ignore_space_change' do
        expect_command_capturing('diff-files', '--ignore-space-change').and_return(command_result(''))

        command.call(b: true)
      end

      it 'includes --ignore-all-space when ignore_all_space: true' do
        expect_command_capturing('diff-files', '--ignore-all-space').and_return(command_result(''))

        command.call(ignore_all_space: true)
      end

      it 'supports :w as alias for :ignore_all_space' do
        expect_command_capturing('diff-files', '--ignore-all-space').and_return(command_result(''))

        command.call(w: true)
      end

      it 'includes --ignore-matching-lines=^# when ignore_matching_lines: "^#"' do
        expect_command_capturing('diff-files', '--ignore-matching-lines=^#').and_return(command_result(''))

        command.call(ignore_matching_lines: '^#')
      end

      it 'repeats --ignore-matching-lines= for each value in an array' do
        expect_command_capturing(
          'diff-files', '--ignore-matching-lines=^#', '--ignore-matching-lines=^//'
        ).and_return(command_result(''))

        command.call(ignore_matching_lines: ['^#', '^//'])
      end

      it 'supports :I as alias for :ignore_matching_lines' do
        expect_command_capturing('diff-files', '--ignore-matching-lines=^#').and_return(command_result(''))

        command.call(I: '^#')
      end

      # RF-1: miscellaneous aliases
      it 'includes --text when text: true' do
        expect_command_capturing('diff-files', '--text').and_return(command_result(''))

        command.call(text: true)
      end

      it 'supports :a as alias for :text' do
        expect_command_capturing('diff-files', '--text').and_return(command_result(''))

        command.call(a: true)
      end

      it 'includes --function-context when function_context: true' do
        expect_command_capturing('diff-files', '--function-context').and_return(command_result(''))

        command.call(function_context: true)
      end

      it 'supports :W as alias for :function_context' do
        expect_command_capturing('diff-files', '--function-context').and_return(command_result(''))

        command.call(W: true)
      end

      it 'includes --irreversible-delete when irreversible_delete: true' do
        expect_command_capturing('diff-files', '--irreversible-delete').and_return(command_result(''))

        command.call(irreversible_delete: true)
      end

      it 'supports :D as alias for :irreversible_delete' do
        expect_command_capturing('diff-files', '--irreversible-delete').and_return(command_result(''))

        command.call(D: true)
      end

      # RF-1: dirstat, break_rewrites, find_copies aliases
      it 'includes --dirstat when dirstat: true' do
        expect_command_capturing('diff-files', '--dirstat').and_return(command_result(''))

        command.call(dirstat: true)
      end

      it 'passes an inline value to --dirstat= when dirstat: is a string' do
        expect_command_capturing('diff-files', '--dirstat=lines,10').and_return(command_result(''))

        command.call(dirstat: 'lines,10')
      end

      it 'supports :X as alias for :dirstat' do
        expect_command_capturing('diff-files', '--dirstat').and_return(command_result(''))

        command.call(X: true)
      end

      it 'includes --break-rewrites when break_rewrites: true' do
        expect_command_capturing('diff-files', '--break-rewrites').and_return(command_result(''))

        command.call(break_rewrites: true)
      end

      it 'passes an inline value to --break-rewrites= when break_rewrites: is a string' do
        expect_command_capturing('diff-files', '--break-rewrites=50/50').and_return(command_result(''))

        command.call(break_rewrites: '50/50')
      end

      it 'supports :B as alias for :break_rewrites' do
        expect_command_capturing('diff-files', '--break-rewrites').and_return(command_result(''))

        command.call(B: true)
      end

      it 'includes --find-copies when find_copies: true' do
        expect_command_capturing('diff-files', '--find-copies').and_return(command_result(''))

        command.call(find_copies: true)
      end

      it 'passes an inline value to --find-copies= when find_copies: is a string' do
        expect_command_capturing('diff-files', '--find-copies=75%').and_return(command_result(''))

        command.call(find_copies: '75%')
      end

      it 'supports :C as alias for :find_copies' do
        expect_command_capturing('diff-files', '--find-copies').and_return(command_result(''))

        command.call(C: true)
      end

      # RF-2: negatable options
      it 'includes --rename-empty when rename_empty: true' do
        expect_command_capturing('diff-files', '--rename-empty').and_return(command_result(''))

        command.call(rename_empty: true)
      end

      it 'includes --no-rename-empty when rename_empty: false' do
        expect_command_capturing('diff-files', '--no-rename-empty').and_return(command_result(''))

        command.call(rename_empty: false)
      end

      it 'includes --ext-diff when ext_diff: true' do
        expect_command_capturing('diff-files', '--ext-diff').and_return(command_result(''))

        command.call(ext_diff: true)
      end

      it 'includes --no-ext-diff when ext_diff: false' do
        expect_command_capturing('diff-files', '--no-ext-diff').and_return(command_result(''))

        command.call(ext_diff: false)
      end

      it 'includes --textconv when textconv: true' do
        expect_command_capturing('diff-files', '--textconv').and_return(command_result(''))

        command.call(textconv: true)
      end

      it 'includes --no-textconv when textconv: false' do
        expect_command_capturing('diff-files', '--no-textconv').and_return(command_result(''))

        command.call(textconv: false)
      end

      it 'includes --color-moved when color_moved: true' do
        expect_command_capturing('diff-files', '--color-moved').and_return(command_result(''))

        command.call(color_moved: true)
      end

      it 'includes --no-color-moved when color_moved: false' do
        expect_command_capturing('diff-files', '--no-color-moved').and_return(command_result(''))

        command.call(color_moved: false)
      end

      it 'includes --color-moved=zebra when color_moved: "zebra"' do
        expect_command_capturing('diff-files', '--color-moved=zebra').and_return(command_result(''))

        command.call(color_moved: 'zebra')
      end

      it 'includes --relative when relative: true' do
        expect_command_capturing('diff-files', '--relative').and_return(command_result(''))

        command.call(relative: true)
      end

      it 'includes --no-relative when relative: false' do
        expect_command_capturing('diff-files', '--no-relative').and_return(command_result(''))

        command.call(relative: false)
      end

      it 'passes an inline value to --relative= when relative: is a string' do
        expect_command_capturing('diff-files', '--relative=lib/').and_return(command_result(''))

        command.call(relative: 'lib/')
      end

      # RF-3: anchored single-value form
      it 'passes a single --anchored= when anchored: is a string' do
        expect_command_capturing('diff-files', '--anchored=ctx1').and_return(command_result(''))

        command.call(anchored: 'ctx1')
      end

      # RF-5: find_renames inline value form
      it 'passes --find-renames=90% when find_renames: "90%"' do
        expect_command_capturing('diff-files', '--find-renames=90%').and_return(command_result(''))

        command.call(find_renames: '90%')
      end
    end

    context 'with path operands' do
      it 'appends a single path after the -- separator' do
        expect_command_capturing('diff-files', '--', 'lib/').and_return(command_result(''))

        command.call('lib/')
      end

      it 'appends multiple paths after the -- separator' do
        expect_command_capturing('diff-files', '--', 'lib/', 'spec/').and_return(command_result(''))

        command.call('lib/', 'spec/')
      end

      it 'places options before -- and paths after' do
        expect_command_capturing('diff-files', '--patch', '--', 'lib/').and_return(command_result(''))

        command.call('lib/', patch: true)
      end
    end

    context 'exit code handling' do
      it 'returns successfully with exit code 0 when no differences' do
        expect_command_capturing('diff-files').and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns successfully with exit code 1 (within allowed range)' do
        expect_command_capturing('diff-files').and_return(command_result('some diff', exitstatus: 1))

        result = command.call

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError when git exits with code 128' do
        expect_command_capturing('diff-files')
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call }.to raise_error(Git::FailedError, /fatal: not a git repository/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported option keys' do
        expect { command.call(totally_unknown: true) }.to raise_error(ArgumentError, /totally_unknown/)
      end
    end
  end
end
