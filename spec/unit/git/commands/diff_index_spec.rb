# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff_index'

RSpec.describe Git::Commands::DiffIndex do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with required tree_ish operand only' do
      it 'runs git diff-index with the tree_ish operand' do
        expected_result = command_result('')
        expect_command_capturing('diff-index', 'HEAD').and_return(expected_result)

        result = command.call('HEAD')

        expect(result).to eq(expected_result)
      end
    end

    context 'with diff-index-specific options' do
      it 'includes -m when m: true' do
        expect_command_capturing('diff-index', '-m', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', m: true)
      end

      it 'includes --cached when cached: true' do
        expect_command_capturing('diff-index', '--cached', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', cached: true)
      end

      it 'includes --merge-base when merge_base: true' do
        expect_command_capturing('diff-index', '--merge-base', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', merge_base: true)
      end
    end

    context 'with output format options' do
      it 'includes --patch when patch: true' do
        expect_command_capturing('diff-index', '--patch', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', patch: true)
      end

      it 'includes --no-patch when no_patch: true' do
        expect_command_capturing('diff-index', '--no-patch', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', no_patch: true)
      end

      it 'includes --raw when raw: true' do
        expect_command_capturing('diff-index', '--raw', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', raw: true)
      end

      it 'includes --numstat when numstat: true' do
        expect_command_capturing('diff-index', '--numstat', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', numstat: true)
      end

      it 'includes --shortstat when shortstat: true' do
        expect_command_capturing('diff-index', '--shortstat', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', shortstat: true)
      end

      it 'includes --stat when stat: true' do
        expect_command_capturing('diff-index', '--stat', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', stat: true)
      end

      it 'passes an inline value to --stat= when stat: is a string' do
        expect_command_capturing('diff-index', '--stat=80,40', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', stat: '80,40')
      end

      it 'includes --name-only when name_only: true' do
        expect_command_capturing('diff-index', '--name-only', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', name_only: true)
      end

      it 'includes --name-status when name_status: true' do
        expect_command_capturing('diff-index', '--name-status', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', name_status: true)
      end
    end

    context 'with diff algorithm options' do
      it 'adds --unified=3 when unified: 3' do
        expect_command_capturing('diff-index', '--unified=3', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', unified: 3)
      end

      it 'adds --diff-algorithm=patience when diff_algorithm: "patience"' do
        expect_command_capturing('diff-index', '--diff-algorithm=patience', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', diff_algorithm: 'patience')
      end

      it 'adds --minimal when minimal: true' do
        expect_command_capturing('diff-index', '--minimal', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', minimal: true)
      end

      it 'adds --patience when patience: true' do
        expect_command_capturing('diff-index', '--patience', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', patience: true)
      end

      it 'adds --histogram when histogram: true' do
        expect_command_capturing('diff-index', '--histogram', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', histogram: true)
      end
    end

    context 'with rename and copy detection options' do
      it 'adds --find-renames when find_renames: true' do
        expect_command_capturing('diff-index', '--find-renames', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', find_renames: true)
      end

      it 'adds --find-renames=90% when find_renames: "90%"' do
        expect_command_capturing('diff-index', '--find-renames=90%', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', find_renames: '90%')
      end

      it 'adds --find-copies when find_copies: true' do
        expect_command_capturing('diff-index', '--find-copies', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', find_copies: true)
      end

      it 'adds --find-copies-harder when find_copies_harder: true' do
        expect_command_capturing('diff-index', '--find-copies-harder', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', find_copies_harder: true)
      end

      it 'adds --break-rewrites when break_rewrites: true' do
        expect_command_capturing('diff-index', '--break-rewrites', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', break_rewrites: true)
      end

      it 'adds --irreversible-delete when irreversible_delete: true' do
        expect_command_capturing('diff-index', '--irreversible-delete', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', irreversible_delete: true)
      end

      it 'adds --no-renames when no_renames: true' do
        expect_command_capturing('diff-index', '--no-renames', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', no_renames: true)
      end

      it 'adds --full-index when full_index: true' do
        expect_command_capturing('diff-index', '--full-index', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', full_index: true)
      end

      it 'adds --binary when binary: true' do
        expect_command_capturing('diff-index', '--binary', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', binary: true)
      end

      it 'adds --abbrev when abbrev: true' do
        expect_command_capturing('diff-index', '--abbrev', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', abbrev: true)
      end

      it 'adds --abbrev=8 when abbrev: 8' do
        expect_command_capturing('diff-index', '--abbrev=8', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', abbrev: 8)
      end

      it 'adds --break-rewrites=60/50 when break_rewrites: "60/50"' do
        expect_command_capturing('diff-index', '--break-rewrites=60/50', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', break_rewrites: '60/50')
      end

      it 'adds --find-copies=80% when find_copies: "80%"' do
        expect_command_capturing('diff-index', '--find-copies=80%', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', find_copies: '80%')
      end
    end

    context 'with output and format display options' do
      it 'includes --patch-with-raw when patch_with_raw: true' do
        expect_command_capturing('diff-index', '--patch-with-raw', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', patch_with_raw: true)
      end

      it 'includes --output=file.diff when output: "file.diff"' do
        expect_command_capturing('diff-index', '--output=file.diff', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', output: 'file.diff')
      end

      it 'includes --output-indicator-new=> when output_indicator_new: ">"' do
        expect_command_capturing('diff-index', '--output-indicator-new=>', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', output_indicator_new: '>')
      end

      it 'includes --output-indicator-old=< when output_indicator_old: "<"' do
        expect_command_capturing('diff-index', '--output-indicator-old=<', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', output_indicator_old: '<')
      end

      it 'includes --output-indicator-context== when output_indicator_context: "="' do
        expect_command_capturing('diff-index', '--output-indicator-context==', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', output_indicator_context: '=')
      end

      it 'includes -z when z: true' do
        expect_command_capturing('diff-index', '-z', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', z: true)
      end

      it 'includes --submodule when submodule: true' do
        expect_command_capturing('diff-index', '--submodule', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', submodule: true)
      end

      it 'includes --submodule=diff when submodule: "diff"' do
        expect_command_capturing('diff-index', '--submodule=diff', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', submodule: 'diff')
      end

      it 'includes --patch-with-stat when patch_with_stat: true' do
        expect_command_capturing('diff-index', '--patch-with-stat', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', patch_with_stat: true)
      end

      it 'includes --summary when summary: true' do
        expect_command_capturing('diff-index', '--summary', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', summary: true)
      end
    end

    context 'with statistics output options' do
      it 'includes --compact-summary when compact_summary: true' do
        expect_command_capturing('diff-index', '--compact-summary', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', compact_summary: true)
      end

      it 'includes --stat-width=80 when stat_width: 80' do
        expect_command_capturing('diff-index', '--stat-width=80', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', stat_width: 80)
      end

      it 'includes --stat-name-width=40 when stat_name_width: 40' do
        expect_command_capturing('diff-index', '--stat-name-width=40', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', stat_name_width: 40)
      end

      it 'includes --stat-graph-width=15 when stat_graph_width: 15' do
        expect_command_capturing('diff-index', '--stat-graph-width=15', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', stat_graph_width: 15)
      end

      it 'includes --stat-count=5 when stat_count: 5' do
        expect_command_capturing('diff-index', '--stat-count=5', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', stat_count: 5)
      end

      it 'includes --cumulative when cumulative: true' do
        expect_command_capturing('diff-index', '--cumulative', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', cumulative: true)
      end

      it 'includes --dirstat when dirstat: true' do
        expect_command_capturing('diff-index', '--dirstat', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', dirstat: true)
      end

      it 'includes --dirstat=cumulative,10 when dirstat: "cumulative,10"' do
        expect_command_capturing('diff-index', '--dirstat=cumulative,10', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', dirstat: 'cumulative,10')
      end

      it 'includes --dirstat-by-file when dirstat_by_file: true' do
        expect_command_capturing('diff-index', '--dirstat-by-file', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', dirstat_by_file: true)
      end

      it 'includes --dirstat-by-file=cumulative when dirstat_by_file: "cumulative"' do
        expect_command_capturing('diff-index', '--dirstat-by-file=cumulative', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', dirstat_by_file: 'cumulative')
      end
    end

    context 'with color and word diff options' do
      it 'includes --color-moved when color_moved: true' do
        expect_command_capturing('diff-index', '--color-moved', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color_moved: true)
      end

      it 'includes --color-moved=zebra when color_moved: "zebra"' do
        expect_command_capturing('diff-index', '--color-moved=zebra', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color_moved: 'zebra')
      end

      it 'includes --no-color-moved when color_moved: false' do
        expect_command_capturing('diff-index', '--no-color-moved', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color_moved: false)
      end

      it 'includes --color-moved-ws=allow-indentation-change when color_moved_ws: "allow-indentation-change"' do
        expect_command_capturing('diff-index', '--color-moved-ws=allow-indentation-change', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color_moved_ws: 'allow-indentation-change')
      end

      it 'includes --no-color-moved-ws when no_color_moved_ws: true' do
        expect_command_capturing('diff-index', '--no-color-moved-ws', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', no_color_moved_ws: true)
      end

      it 'includes --word-diff when word_diff: true' do
        expect_command_capturing('diff-index', '--word-diff', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', word_diff: true)
      end

      it 'includes --word-diff=color when word_diff: "color"' do
        expect_command_capturing('diff-index', '--word-diff=color', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', word_diff: 'color')
      end

      it 'includes --word-diff-regex=pattern when word_diff_regex: "pattern"' do
        expect_command_capturing('diff-index', '--word-diff-regex=pattern', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', word_diff_regex: 'pattern')
      end

      it 'includes --color-words when color_words: true' do
        expect_command_capturing('diff-index', '--color-words', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color_words: true)
      end

      it 'includes --color-words=pattern when color_words: "pattern"' do
        expect_command_capturing('diff-index', '--color-words=pattern', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color_words: 'pattern')
      end
    end

    context 'with whitespace handling options' do
      it 'includes --ignore-cr-at-eol when ignore_cr_at_eol: true' do
        expect_command_capturing('diff-index', '--ignore-cr-at-eol', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_cr_at_eol: true)
      end

      it 'includes --ignore-space-at-eol when ignore_space_at_eol: true' do
        expect_command_capturing('diff-index', '--ignore-space-at-eol', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_space_at_eol: true)
      end

      it 'includes --ignore-space-change when ignore_space_change: true' do
        expect_command_capturing('diff-index', '--ignore-space-change', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_space_change: true)
      end

      it 'includes --ignore-all-space when ignore_all_space: true' do
        expect_command_capturing('diff-index', '--ignore-all-space', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_all_space: true)
      end

      it 'includes --ignore-blank-lines when ignore_blank_lines: true' do
        expect_command_capturing('diff-index', '--ignore-blank-lines', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_blank_lines: true)
      end

      it 'includes --ignore-matching-lines=TODO when ignore_matching_lines: "TODO"' do
        expect_command_capturing('diff-index', '--ignore-matching-lines=TODO', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_matching_lines: 'TODO')
      end

      it 'repeats --ignore-matching-lines= for each value in an array' do
        expect_command_capturing('diff-index', '--ignore-matching-lines=TODO', '--ignore-matching-lines=FIXME', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_matching_lines: %w[TODO FIXME])
      end

      it 'includes --check when check: true' do
        expect_command_capturing('diff-index', '--check', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', check: true)
      end

      it 'includes --ws-error-highlight=old,new when ws_error_highlight: "old,new"' do
        expect_command_capturing('diff-index', '--ws-error-highlight=old,new', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ws_error_highlight: 'old,new')
      end
    end

    context 'with pickaxe and filtering options' do
      it 'includes -l200 when l: 200' do
        expect_command_capturing('diff-index', '-l200', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', l: 200)
      end

      it 'includes --diff-filter=ACMR when diff_filter: "ACMR"' do
        expect_command_capturing('diff-index', '--diff-filter=ACMR', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', diff_filter: 'ACMR')
      end

      it 'includes -Ssearch when S: "search"' do
        expect_command_capturing('diff-index', '-Ssearch', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', S: 'search')
      end

      it 'includes -Gpattern when G: "pattern"' do
        expect_command_capturing('diff-index', '-Gpattern', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', G: 'pattern')
      end

      it 'includes --find-object=abc123 when find_object: "abc123"' do
        expect_command_capturing('diff-index', '--find-object=abc123', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', find_object: 'abc123')
      end

      it 'includes --pickaxe-all when pickaxe_all: true' do
        expect_command_capturing('diff-index', '--pickaxe-all', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pickaxe_all: true)
      end

      it 'includes --pickaxe-regex when pickaxe_regex: true' do
        expect_command_capturing('diff-index', '--pickaxe-regex', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', pickaxe_regex: true)
      end

      it 'includes -Oorder.txt when O: "order.txt"' do
        expect_command_capturing('diff-index', '-Oorder.txt', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', O: 'order.txt')
      end

      it 'includes --skip-to=file.txt when skip_to: "file.txt"' do
        expect_command_capturing('diff-index', '--skip-to=file.txt', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', skip_to: 'file.txt')
      end

      it 'includes --rotate-to=file.txt when rotate_to: "file.txt"' do
        expect_command_capturing('diff-index', '--rotate-to=file.txt', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', rotate_to: 'file.txt')
      end
    end

    context 'with miscellaneous diff options' do
      it 'includes -R when R: true' do
        expect_command_capturing('diff-index', '-R', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', R: true)
      end

      it 'includes --relative when relative: true' do
        expect_command_capturing('diff-index', '--relative', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', relative: true)
      end

      it 'includes --relative=src/ when relative: "src/"' do
        expect_command_capturing('diff-index', '--relative=src/', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', relative: 'src/')
      end

      it 'includes --no-relative when relative: false' do
        expect_command_capturing('diff-index', '--no-relative', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', relative: false)
      end

      it 'includes --text when text: true' do
        expect_command_capturing('diff-index', '--text', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', text: true)
      end

      it 'includes --function-context when function_context: true' do
        expect_command_capturing('diff-index', '--function-context', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', function_context: true)
      end

      it 'includes --inter-hunk-context=3 when inter_hunk_context: 3' do
        expect_command_capturing('diff-index', '--inter-hunk-context=3', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', inter_hunk_context: 3)
      end

      it 'includes --exit-code when exit_code: true' do
        expect_command_capturing('diff-index', '--exit-code', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', exit_code: true)
      end

      it 'includes --quiet when quiet: true' do
        expect_command_capturing('diff-index', '--quiet', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', quiet: true)
      end

      it 'includes --textconv when textconv: true' do
        expect_command_capturing('diff-index', '--textconv', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', textconv: true)
      end

      it 'includes --no-textconv when textconv: false' do
        expect_command_capturing('diff-index', '--no-textconv', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', textconv: false)
      end

      it 'includes --ignore-submodules when ignore_submodules: true' do
        expect_command_capturing('diff-index', '--ignore-submodules', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_submodules: true)
      end

      it 'includes --ignore-submodules=all when ignore_submodules: "all"' do
        expect_command_capturing('diff-index', '--ignore-submodules=all', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ignore_submodules: 'all')
      end

      it 'includes --ita-invisible-in-index when ita_invisible_in_index: true' do
        expect_command_capturing('diff-index', '--ita-invisible-in-index', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ita_invisible_in_index: true)
      end

      it 'includes --max-depth=2 when max_depth: 2' do
        expect_command_capturing('diff-index', '--max-depth=2', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', max_depth: 2)
      end
    end

    context 'with prefix and line display options' do
      it 'includes --src-prefix=a/ when src_prefix: "a/"' do
        expect_command_capturing('diff-index', '--src-prefix=a/', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', src_prefix: 'a/')
      end

      it 'includes --dst-prefix=b/ when dst_prefix: "b/"' do
        expect_command_capturing('diff-index', '--dst-prefix=b/', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', dst_prefix: 'b/')
      end

      it 'includes --no-prefix when no_prefix: true' do
        expect_command_capturing('diff-index', '--no-prefix', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', no_prefix: true)
      end

      it 'includes --default-prefix when default_prefix: true' do
        expect_command_capturing('diff-index', '--default-prefix', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', default_prefix: true)
      end

      it 'includes --line-prefix=| when line_prefix: "| "' do
        expect_command_capturing('diff-index', '--line-prefix=| ', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', line_prefix: '| ')
      end
    end

    context 'with repeatable options' do
      it 'includes --anchored=context when anchored: "context"' do
        expect_command_capturing('diff-index', '--anchored=context', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', anchored: 'context')
      end

      it 'repeats --anchored= for each value in an array' do
        expect_command_capturing('diff-index', '--anchored=ctx1', '--anchored=ctx2', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', anchored: %w[ctx1 ctx2])
      end
    end

    context 'with path operands' do
      it 'appends a single path after the tree_ish operand with -- separator' do
        expect_command_capturing('diff-index', 'HEAD', '--', 'lib/')
          .and_return(command_result(''))

        command.call('HEAD', 'lib/')
      end

      it 'appends multiple paths after the tree_ish operand with -- separator' do
        expect_command_capturing('diff-index', 'HEAD', '--', 'lib/', 'spec/')
          .and_return(command_result(''))

        command.call('HEAD', 'lib/', 'spec/')
      end

      it 'places options before tree_ish and paths after the -- separator' do
        expect_command_capturing('diff-index', '--cached', 'HEAD', '--', 'lib/')
          .and_return(command_result(''))

        command.call('HEAD', 'lib/', cached: true)
      end
    end

    context 'with DSL option aliases' do
      it 'supports :p as alias for :patch' do
        expect_command_capturing('diff-index', '--patch', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', p: true)
      end

      it 'supports :u as alias for :patch' do
        expect_command_capturing('diff-index', '--patch', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', u: true)
      end

      it 'supports :s as alias for :no_patch' do
        expect_command_capturing('diff-index', '--no-patch', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', s: true)
      end

      it 'supports :M as alias for :find_renames' do
        expect_command_capturing('diff-index', '--find-renames', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', M: true)
      end

      it 'supports :C as alias for :find_copies' do
        expect_command_capturing('diff-index', '--find-copies', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', C: true)
      end

      it 'supports :B as alias for :break_rewrites' do
        expect_command_capturing('diff-index', '--break-rewrites', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', B: true)
      end

      it 'supports :D as alias for :irreversible_delete' do
        expect_command_capturing('diff-index', '--irreversible-delete', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', D: true)
      end

      it 'supports :X as alias for :dirstat' do
        expect_command_capturing('diff-index', '--dirstat', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', X: true)
      end

      it 'supports :W as alias for :function_context' do
        expect_command_capturing('diff-index', '--function-context', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', W: true)
      end

      it 'supports :b as alias for :ignore_space_change' do
        expect_command_capturing('diff-index', '--ignore-space-change', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', b: true)
      end

      it 'supports :w as alias for :ignore_all_space' do
        expect_command_capturing('diff-index', '--ignore-all-space', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', w: true)
      end

      it 'supports :a as alias for :text' do
        expect_command_capturing('diff-index', '--text', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', a: true)
      end

      it 'supports :U as alias for :unified' do
        expect_command_capturing('diff-index', '--unified=5', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', U: 5)
      end

      it 'supports :I as alias for :ignore_matching_lines' do
        expect_command_capturing('diff-index', '--ignore-matching-lines=TODO', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', I: 'TODO')
      end
    end

    context 'with negatable options' do
      it 'adds --indent-heuristic when indent_heuristic: true' do
        expect_command_capturing('diff-index', '--indent-heuristic', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', indent_heuristic: true)
      end

      it 'adds --no-indent-heuristic when indent_heuristic: false' do
        expect_command_capturing('diff-index', '--no-indent-heuristic', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', indent_heuristic: false)
      end

      it 'adds --color when color: true' do
        expect_command_capturing('diff-index', '--color', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color: true)
      end

      it 'adds --no-color when color: false' do
        expect_command_capturing('diff-index', '--no-color', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color: false)
      end

      it 'adds --color=always when color: "always"' do
        expect_command_capturing('diff-index', '--color=always', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', color: 'always')
      end

      it 'adds --ext-diff when ext_diff: true' do
        expect_command_capturing('diff-index', '--ext-diff', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ext_diff: true)
      end

      it 'adds --no-ext-diff when ext_diff: false' do
        expect_command_capturing('diff-index', '--no-ext-diff', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', ext_diff: false)
      end

      it 'adds --rename-empty when rename_empty: true' do
        expect_command_capturing('diff-index', '--rename-empty', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', rename_empty: true)
      end

      it 'adds --no-rename-empty when rename_empty: false' do
        expect_command_capturing('diff-index', '--no-rename-empty', 'HEAD')
          .and_return(command_result(''))

        command.call('HEAD', rename_empty: false)
      end
    end

    context 'exit code handling' do
      it 'returns successfully with exit code 0 when no differences' do
        expect_command_capturing('diff-index', 'HEAD')
          .and_return(command_result('', exitstatus: 0))

        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns successfully with exit code 1 (within allowed range)' do
        expect_command_capturing('diff-index', 'HEAD')
          .and_return(command_result('', exitstatus: 1))

        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError when git exits with code 2 or higher' do
        expect_command_capturing('diff-index', 'HEAD')
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 128))

        expect { command.call('HEAD') }.to raise_error(Git::FailedError, /fatal: bad revision/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when tree_ish is not provided' do
        expect { command.call }.to raise_error(ArgumentError, /tree_ish/)
      end

      it 'raises ArgumentError for unsupported option keys' do
        expect { command.call('HEAD', totally_unknown: true) }.to raise_error(ArgumentError, /totally_unknown/)
      end
    end
  end
end
