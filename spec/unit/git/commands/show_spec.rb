# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show'

RSpec.describe Git::Commands::Show do
  # Duck-type collaborator: command specs depend on the #command_capturing and
  # #command_streaming interfaces, not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git show with no extra arguments and returns the result' do
        expected_result = command_result
        expect_command_capturing('show', chomp: false).and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a single object' do
      it 'passes the object specifier to git show' do
        expect_command_capturing('show', 'HEAD', chomp: false).and_return(command_result)

        command.call('HEAD')
      end
    end

    context 'with an objectish:path expression' do
      it 'passes the combined expression as a single argument' do
        expect_command_capturing('show', 'abc123:README.md', chomp: false).and_return(command_result)

        command.call('abc123:README.md')
      end
    end

    context 'with multiple objects' do
      it 'passes each object specifier as a separate argument' do
        expect_command_capturing('show', 'v1.0', 'v2.0', chomp: false).and_return(command_result)

        command.call('v1.0', 'v2.0')
      end
    end

    # Commit formatting options

    context 'with the :pretty option' do
      it 'adds --pretty to the command line when given true' do
        expect_command_capturing('show', '--pretty', chomp: false).and_return(command_result)

        command.call(pretty: true)
      end

      it 'adds --pretty=<format> when given a string' do
        expect_command_capturing('show', '--pretty=oneline', chomp: false).and_return(command_result)

        command.call(pretty: 'oneline')
      end
    end

    context 'with the :format option' do
      it 'adds --format=<format> to the command line' do
        expect_command_capturing('show', '--format=%H', chomp: false).and_return(command_result)

        command.call(format: '%H')
      end
    end

    context 'with the :abbrev_commit option' do
      it 'adds --abbrev-commit to the command line' do
        expect_command_capturing('show', '--abbrev-commit', chomp: false).and_return(command_result)

        command.call(abbrev_commit: true)
      end

      it 'adds --no-abbrev-commit when negated' do
        expect_command_capturing('show', '--no-abbrev-commit', chomp: false).and_return(command_result)

        command.call(abbrev_commit: false)
      end
    end

    context 'with the :oneline option' do
      it 'adds --oneline to the command line' do
        expect_command_capturing('show', '--oneline', chomp: false).and_return(command_result)

        command.call(oneline: true)
      end
    end

    context 'with the :encoding option' do
      it 'adds --encoding=<enc> to the command line' do
        expect_command_capturing('show', '--encoding=UTF-8', chomp: false).and_return(command_result)

        command.call(encoding: 'UTF-8')
      end
    end

    context 'with the :expand_tabs option' do
      it 'adds --expand-tabs to the command line when given true' do
        expect_command_capturing('show', '--expand-tabs', chomp: false).and_return(command_result)

        command.call(expand_tabs: true)
      end

      it 'adds --expand-tabs=<n> when given an integer' do
        expect_command_capturing('show', '--expand-tabs=4', chomp: false).and_return(command_result)

        command.call(expand_tabs: 4)
      end

      it 'adds --no-expand-tabs when negated' do
        expect_command_capturing('show', '--no-expand-tabs', chomp: false).and_return(command_result)

        command.call(expand_tabs: false)
      end
    end

    context 'with the :notes option' do
      it 'adds --notes to the command line when given true' do
        expect_command_capturing('show', '--notes', chomp: false).and_return(command_result)

        command.call(notes: true)
      end

      it 'adds --notes=<ref> when given a string' do
        expect_command_capturing('show', '--notes=refs/notes/review', chomp: false).and_return(command_result)

        command.call(notes: 'refs/notes/review')
      end

      it 'adds --no-notes when negated' do
        expect_command_capturing('show', '--no-notes', chomp: false).and_return(command_result)

        command.call(notes: false)
      end
    end

    context 'with the :show_notes_by_default option' do
      it 'adds --show-notes-by-default to the command line' do
        expect_command_capturing('show', '--show-notes-by-default', chomp: false).and_return(command_result)

        command.call(show_notes_by_default: true)
      end
    end

    context 'with the :show_notes option' do
      it 'adds --show-notes to the command line when given true' do
        expect_command_capturing('show', '--show-notes', chomp: false).and_return(command_result)

        command.call(show_notes: true)
      end

      it 'adds --show-notes=<ref> when given a string' do
        expect_command_capturing('show', '--show-notes=refs/notes/review', chomp: false).and_return(command_result)

        command.call(show_notes: 'refs/notes/review')
      end
    end

    context 'with the :standard_notes option' do
      it 'adds --standard-notes to the command line' do
        expect_command_capturing('show', '--standard-notes', chomp: false).and_return(command_result)

        command.call(standard_notes: true)
      end

      it 'adds --no-standard-notes when negated' do
        expect_command_capturing('show', '--no-standard-notes', chomp: false).and_return(command_result)

        command.call(standard_notes: false)
      end
    end

    context 'with the :show_signature option' do
      it 'adds --show-signature to the command line' do
        expect_command_capturing('show', '--show-signature', chomp: false).and_return(command_result)

        command.call(show_signature: true)
      end
    end

    # Merge diff format options

    context 'with the :m option' do
      it 'adds -m to the command line' do
        expect_command_capturing('show', '-m', chomp: false).and_return(command_result)

        command.call(m: true)
      end
    end

    context 'with the :c option' do
      it 'adds -c to the command line' do
        expect_command_capturing('show', '-c', chomp: false).and_return(command_result)

        command.call(c: true)
      end
    end

    context 'with the :cc option' do
      it 'adds --cc to the command line' do
        expect_command_capturing('show', '--cc', chomp: false).and_return(command_result)

        command.call(cc: true)
      end
    end

    context 'with the :dd option' do
      it 'adds --dd to the command line' do
        expect_command_capturing('show', '--dd', chomp: false).and_return(command_result)

        command.call(dd: true)
      end
    end

    context 'with the :remerge_diff option' do
      it 'adds --remerge-diff to the command line' do
        expect_command_capturing('show', '--remerge-diff', chomp: false).and_return(command_result)

        command.call(remerge_diff: true)
      end
    end

    context 'with the :no_diff_merges option' do
      it 'adds --no-diff-merges to the command line' do
        expect_command_capturing('show', '--no-diff-merges', chomp: false).and_return(command_result)

        command.call(no_diff_merges: true)
      end
    end

    context 'with the :diff_merges option' do
      it 'adds --diff-merges=<format> to the command line' do
        expect_command_capturing('show', '--diff-merges=combined', chomp: false).and_return(command_result)

        command.call(diff_merges: 'combined')
      end
    end

    context 'with the :combined_all_paths option' do
      it 'adds --combined-all-paths to the command line' do
        expect_command_capturing('show', '--combined-all-paths', chomp: false).and_return(command_result)

        command.call(combined_all_paths: true)
      end
    end

    # Output format options

    context 'with the :patch option' do
      it 'adds --patch to the command line' do
        expect_command_capturing('show', '--patch', chomp: false).and_return(command_result)

        command.call(patch: true)
      end

      it 'supports the :p alias' do
        expect_command_capturing('show', '--patch', chomp: false).and_return(command_result)

        command.call(p: true)
      end

      it 'supports the :u alias' do
        expect_command_capturing('show', '--patch', chomp: false).and_return(command_result)

        command.call(u: true)
      end
    end

    context 'with the :no_patch option' do
      it 'adds --no-patch to the command line' do
        expect_command_capturing('show', '--no-patch', chomp: false).and_return(command_result)

        command.call(no_patch: true)
      end

      it 'supports the :s alias' do
        expect_command_capturing('show', '--no-patch', chomp: false).and_return(command_result)

        command.call(s: true)
      end
    end

    context 'with the :unified option' do
      it 'adds --unified=<n> to the command line' do
        expect_command_capturing('show', '--unified=5', chomp: false).and_return(command_result)

        command.call(unified: 5)
      end

      it 'supports the :U alias' do
        expect_command_capturing('show', '--unified=5', chomp: false).and_return(command_result)

        command.call(U: 5)
      end
    end

    context 'with the :output option' do
      it 'adds --output=<file> to the command line' do
        expect_command_capturing('show', '--output=patch.diff', chomp: false).and_return(command_result)

        command.call(output: 'patch.diff')
      end
    end

    context 'with the :output_indicator_new option' do
      it 'adds --output-indicator-new=<char> to the command line' do
        expect_command_capturing('show', '--output-indicator-new=>', chomp: false).and_return(command_result)

        command.call(output_indicator_new: '>')
      end
    end

    context 'with the :output_indicator_old option' do
      it 'adds --output-indicator-old=<char> to the command line' do
        expect_command_capturing('show', '--output-indicator-old=<', chomp: false).and_return(command_result)

        command.call(output_indicator_old: '<')
      end
    end

    context 'with the :output_indicator_context option' do
      it 'adds --output-indicator-context=<char> to the command line' do
        expect_command_capturing('show', '--output-indicator-context= ', chomp: false).and_return(command_result)

        command.call(output_indicator_context: ' ')
      end
    end

    context 'with the :raw option' do
      it 'adds --raw to the command line' do
        expect_command_capturing('show', '--raw', chomp: false).and_return(command_result)

        command.call(raw: true)
      end
    end

    context 'with the :patch_with_raw option' do
      it 'adds --patch-with-raw to the command line' do
        expect_command_capturing('show', '--patch-with-raw', chomp: false).and_return(command_result)

        command.call(patch_with_raw: true)
      end
    end

    context 'with the :t option' do
      it 'adds -t to the command line' do
        expect_command_capturing('show', '-t', chomp: false).and_return(command_result)

        command.call(t: true)
      end
    end

    context 'with the :indent_heuristic option' do
      it 'adds --indent-heuristic to the command line' do
        expect_command_capturing('show', '--indent-heuristic', chomp: false).and_return(command_result)

        command.call(indent_heuristic: true)
      end

      it 'adds --no-indent-heuristic when negated' do
        expect_command_capturing('show', '--no-indent-heuristic', chomp: false).and_return(command_result)

        command.call(indent_heuristic: false)
      end
    end

    context 'with the :minimal option' do
      it 'adds --minimal to the command line' do
        expect_command_capturing('show', '--minimal', chomp: false).and_return(command_result)

        command.call(minimal: true)
      end
    end

    context 'with the :patience option' do
      it 'adds --patience to the command line' do
        expect_command_capturing('show', '--patience', chomp: false).and_return(command_result)

        command.call(patience: true)
      end
    end

    context 'with the :histogram option' do
      it 'adds --histogram to the command line' do
        expect_command_capturing('show', '--histogram', chomp: false).and_return(command_result)

        command.call(histogram: true)
      end
    end

    context 'with the :anchored option' do
      it 'adds --anchored=<text> to the command line' do
        expect_command_capturing('show', '--anchored=context', chomp: false).and_return(command_result)

        command.call(anchored: 'context')
      end

      it 'adds multiple --anchored flags when given an array' do
        expect_command_capturing('show', '--anchored=text1', '--anchored=text2',
                                 chomp: false).and_return(command_result)

        command.call(anchored: %w[text1 text2])
      end
    end

    context 'with the :diff_algorithm option' do
      it 'adds --diff-algorithm=<algo> to the command line' do
        expect_command_capturing('show', '--diff-algorithm=patience', chomp: false).and_return(command_result)

        command.call(diff_algorithm: 'patience')
      end
    end

    context 'with the :stat option' do
      it 'adds --stat to the command line when given true' do
        expect_command_capturing('show', '--stat', chomp: false).and_return(command_result)

        command.call(stat: true)
      end

      it 'adds --stat=<n> when given a string' do
        expect_command_capturing('show', '--stat=80', chomp: false).and_return(command_result)

        command.call(stat: '80')
      end
    end

    context 'with the :stat_width option' do
      it 'adds --stat-width=<n> to the command line' do
        expect_command_capturing('show', '--stat-width=80', chomp: false).and_return(command_result)

        command.call(stat_width: '80')
      end
    end

    context 'with the :stat_name_width option' do
      it 'adds --stat-name-width=<n> to the command line' do
        expect_command_capturing('show', '--stat-name-width=40', chomp: false).and_return(command_result)

        command.call(stat_name_width: '40')
      end
    end

    context 'with the :stat_count option' do
      it 'adds --stat-count=<n> to the command line' do
        expect_command_capturing('show', '--stat-count=10', chomp: false).and_return(command_result)

        command.call(stat_count: '10')
      end
    end

    context 'with the :stat_graph_width option' do
      it 'adds --stat-graph-width=<n> to the command line' do
        expect_command_capturing('show', '--stat-graph-width=50', chomp: false).and_return(command_result)

        command.call(stat_graph_width: '50')
      end
    end

    context 'with the :compact_summary option' do
      it 'adds --compact-summary to the command line' do
        expect_command_capturing('show', '--compact-summary', chomp: false).and_return(command_result)

        command.call(compact_summary: true)
      end
    end

    context 'with the :numstat option' do
      it 'adds --numstat to the command line' do
        expect_command_capturing('show', '--numstat', chomp: false).and_return(command_result)

        command.call(numstat: true)
      end
    end

    context 'with the :shortstat option' do
      it 'adds --shortstat to the command line' do
        expect_command_capturing('show', '--shortstat', chomp: false).and_return(command_result)

        command.call(shortstat: true)
      end
    end

    context 'with the :dirstat option' do
      it 'adds --dirstat to the command line when given true' do
        expect_command_capturing('show', '--dirstat', chomp: false).and_return(command_result)

        command.call(dirstat: true)
      end

      it 'adds --dirstat=<param> when given a string' do
        expect_command_capturing('show', '--dirstat=lines,cumulative', chomp: false).and_return(command_result)

        command.call(dirstat: 'lines,cumulative')
      end

      it 'supports the :X alias' do
        expect_command_capturing('show', '--dirstat', chomp: false).and_return(command_result)

        command.call(X: true)
      end
    end

    context 'with the :cumulative option' do
      it 'adds --cumulative to the command line' do
        expect_command_capturing('show', '--cumulative', chomp: false).and_return(command_result)

        command.call(cumulative: true)
      end
    end

    context 'with the :dirstat_by_file option' do
      it 'adds --dirstat-by-file to the command line when given true' do
        expect_command_capturing('show', '--dirstat-by-file', chomp: false).and_return(command_result)

        command.call(dirstat_by_file: true)
      end

      it 'adds --dirstat-by-file=<n> when given a string' do
        expect_command_capturing('show', '--dirstat-by-file=10', chomp: false).and_return(command_result)

        command.call(dirstat_by_file: '10')
      end
    end

    context 'with the :summary option' do
      it 'adds --summary to the command line' do
        expect_command_capturing('show', '--summary', chomp: false).and_return(command_result)

        command.call(summary: true)
      end
    end

    context 'with the :patch_with_stat option' do
      it 'adds --patch-with-stat to the command line' do
        expect_command_capturing('show', '--patch-with-stat', chomp: false).and_return(command_result)

        command.call(patch_with_stat: true)
      end
    end

    context 'with the :z option' do
      it 'adds -z to the command line' do
        expect_command_capturing('show', '-z', chomp: false).and_return(command_result)

        command.call(z: true)
      end
    end

    context 'with the :name_only option' do
      it 'adds --name-only to the command line' do
        expect_command_capturing('show', '--name-only', chomp: false).and_return(command_result)

        command.call(name_only: true)
      end
    end

    context 'with the :name_status option' do
      it 'adds --name-status to the command line' do
        expect_command_capturing('show', '--name-status', chomp: false).and_return(command_result)

        command.call(name_status: true)
      end
    end

    context 'with the :submodule option' do
      it 'adds --submodule to the command line when given true' do
        expect_command_capturing('show', '--submodule', chomp: false).and_return(command_result)

        command.call(submodule: true)
      end

      it 'adds --submodule=<format> when given a string' do
        expect_command_capturing('show', '--submodule=log', chomp: false).and_return(command_result)

        command.call(submodule: 'log')
      end
    end

    # Color and word diff options

    context 'with the :color option' do
      it 'adds --color to the command line when given true' do
        expect_command_capturing('show', '--color', chomp: false).and_return(command_result)

        command.call(color: true)
      end

      it 'adds --color=<when> when given a string' do
        expect_command_capturing('show', '--color=always', chomp: false).and_return(command_result)

        command.call(color: 'always')
      end

      it 'adds --no-color when negated' do
        expect_command_capturing('show', '--no-color', chomp: false).and_return(command_result)

        command.call(color: false)
      end
    end

    context 'with the :color_moved option' do
      it 'adds --color-moved to the command line when given true' do
        expect_command_capturing('show', '--color-moved', chomp: false).and_return(command_result)

        command.call(color_moved: true)
      end

      it 'adds --color-moved=<mode> when given a string' do
        expect_command_capturing('show', '--color-moved=zebra', chomp: false).and_return(command_result)

        command.call(color_moved: 'zebra')
      end

      it 'adds --no-color-moved when negated' do
        expect_command_capturing('show', '--no-color-moved', chomp: false).and_return(command_result)

        command.call(color_moved: false)
      end
    end

    context 'with the :color_moved_ws option' do
      it 'adds --color-moved-ws to the command line when given true' do
        expect_command_capturing('show', '--color-moved-ws', chomp: false).and_return(command_result)

        command.call(color_moved_ws: true)
      end

      it 'adds --color-moved-ws=<mode> when given a string' do
        expect_command_capturing('show', '--color-moved-ws=ignore-all-space', chomp: false).and_return(command_result)

        command.call(color_moved_ws: 'ignore-all-space')
      end

      it 'adds --no-color-moved-ws when negated' do
        expect_command_capturing('show', '--no-color-moved-ws', chomp: false).and_return(command_result)

        command.call(color_moved_ws: false)
      end
    end

    context 'with the :word_diff option' do
      it 'adds --word-diff to the command line when given true' do
        expect_command_capturing('show', '--word-diff', chomp: false).and_return(command_result)

        command.call(word_diff: true)
      end

      it 'adds --word-diff=<mode> when given a string' do
        expect_command_capturing('show', '--word-diff=color', chomp: false).and_return(command_result)

        command.call(word_diff: 'color')
      end
    end

    context 'with the :word_diff_regex option' do
      it 'adds --word-diff-regex=<pattern> to the command line' do
        expect_command_capturing('show', '--word-diff-regex=\w+', chomp: false).and_return(command_result)

        command.call(word_diff_regex: '\w+')
      end
    end

    context 'with the :color_words option' do
      it 'adds --color-words to the command line when given true' do
        expect_command_capturing('show', '--color-words', chomp: false).and_return(command_result)

        command.call(color_words: true)
      end

      it 'adds --color-words=<pattern> when given a string' do
        expect_command_capturing('show', '--color-words=\w+', chomp: false).and_return(command_result)

        command.call(color_words: '\w+')
      end
    end

    # Rename and copy detection options

    context 'with the :no_renames option' do
      it 'adds --no-renames to the command line' do
        expect_command_capturing('show', '--no-renames', chomp: false).and_return(command_result)

        command.call(no_renames: true)
      end
    end

    context 'with the :rename_empty option' do
      it 'adds --rename-empty to the command line' do
        expect_command_capturing('show', '--rename-empty', chomp: false).and_return(command_result)

        command.call(rename_empty: true)
      end

      it 'adds --no-rename-empty when negated' do
        expect_command_capturing('show', '--no-rename-empty', chomp: false).and_return(command_result)

        command.call(rename_empty: false)
      end
    end

    context 'with the :check option' do
      it 'adds --check to the command line' do
        expect_command_capturing('show', '--check', chomp: false).and_return(command_result)

        command.call(check: true)
      end
    end

    context 'with the :ws_error_highlight option' do
      it 'adds --ws-error-highlight=<kind> to the command line' do
        expect_command_capturing('show', '--ws-error-highlight=all', chomp: false).and_return(command_result)

        command.call(ws_error_highlight: 'all')
      end
    end

    context 'with the :full_index option' do
      it 'adds --full-index to the command line' do
        expect_command_capturing('show', '--full-index', chomp: false).and_return(command_result)

        command.call(full_index: true)
      end
    end

    context 'with the :binary option' do
      it 'adds --binary to the command line' do
        expect_command_capturing('show', '--binary', chomp: false).and_return(command_result)

        command.call(binary: true)
      end
    end

    context 'with the :abbrev option' do
      it 'adds --abbrev to the command line when given true' do
        expect_command_capturing('show', '--abbrev', chomp: false).and_return(command_result)

        command.call(abbrev: true)
      end

      it 'adds --abbrev=<n> when given a string' do
        expect_command_capturing('show', '--abbrev=10', chomp: false).and_return(command_result)

        command.call(abbrev: '10')
      end
    end

    context 'with the :break_rewrites option' do
      it 'adds --break-rewrites to the command line when given true' do
        expect_command_capturing('show', '--break-rewrites', chomp: false).and_return(command_result)

        command.call(break_rewrites: true)
      end

      it 'adds --break-rewrites=<n> when given a string' do
        expect_command_capturing('show', '--break-rewrites=50%', chomp: false).and_return(command_result)

        command.call(break_rewrites: '50%')
      end

      it 'supports the :B alias' do
        expect_command_capturing('show', '--break-rewrites', chomp: false).and_return(command_result)

        command.call(B: true)
      end
    end

    context 'with the :find_renames option' do
      it 'adds --find-renames to the command line when given true' do
        expect_command_capturing('show', '--find-renames', chomp: false).and_return(command_result)

        command.call(find_renames: true)
      end

      it 'adds --find-renames=<n>% when given a string' do
        expect_command_capturing('show', '--find-renames=90%', chomp: false).and_return(command_result)

        command.call(find_renames: '90%')
      end

      it 'supports the :M alias' do
        expect_command_capturing('show', '--find-renames', chomp: false).and_return(command_result)

        command.call(M: true)
      end
    end

    context 'with the :find_copies option' do
      it 'adds --find-copies to the command line when given true' do
        expect_command_capturing('show', '--find-copies', chomp: false).and_return(command_result)

        command.call(find_copies: true)
      end

      it 'adds --find-copies=<n>% when given a string' do
        expect_command_capturing('show', '--find-copies=90%', chomp: false).and_return(command_result)

        command.call(find_copies: '90%')
      end

      it 'supports the :C alias' do
        expect_command_capturing('show', '--find-copies', chomp: false).and_return(command_result)

        command.call(C: true)
      end
    end

    context 'with the :find_copies_harder option' do
      it 'adds --find-copies-harder to the command line' do
        expect_command_capturing('show', '--find-copies-harder', chomp: false).and_return(command_result)

        command.call(find_copies_harder: true)
      end
    end

    context 'with the :irreversible_delete option' do
      it 'adds --irreversible-delete to the command line' do
        expect_command_capturing('show', '--irreversible-delete', chomp: false).and_return(command_result)

        command.call(irreversible_delete: true)
      end

      it 'supports the :D alias' do
        expect_command_capturing('show', '--irreversible-delete', chomp: false).and_return(command_result)

        command.call(D: true)
      end
    end

    context 'with the :l option' do
      it 'adds -l<n> to the command line' do
        expect_command_capturing('show', '-l10', chomp: false).and_return(command_result)

        command.call(l: '10')
      end
    end

    context 'with the :diff_filter option' do
      it 'adds --diff-filter=<filter> to the command line' do
        expect_command_capturing('show', '--diff-filter=M', chomp: false).and_return(command_result)

        command.call(diff_filter: 'M')
      end
    end

    # Content search (pickaxe) options

    context 'with the :S option' do
      it 'adds -S<string> to the command line' do
        expect_command_capturing('show', '-Ssearch_string', chomp: false).and_return(command_result)

        command.call(S: 'search_string')
      end
    end

    context 'with the :G option' do
      it 'adds -G<regex> to the command line' do
        expect_command_capturing('show', '-Gregex', chomp: false).and_return(command_result)

        command.call(G: 'regex')
      end
    end

    context 'with the :find_object option' do
      it 'adds --find-object=<object> to the command line' do
        expect_command_capturing('show', '--find-object=abc123', chomp: false).and_return(command_result)

        command.call(find_object: 'abc123')
      end
    end

    context 'with the :pickaxe_all option' do
      it 'adds --pickaxe-all to the command line' do
        expect_command_capturing('show', '--pickaxe-all', chomp: false).and_return(command_result)

        command.call(pickaxe_all: true)
      end
    end

    context 'with the :pickaxe_regex option' do
      it 'adds --pickaxe-regex to the command line' do
        expect_command_capturing('show', '--pickaxe-regex', chomp: false).and_return(command_result)

        command.call(pickaxe_regex: true)
      end
    end

    # Output ordering options

    context 'with the :O option' do
      it 'adds -O<file> to the command line' do
        expect_command_capturing('show', '-Oorder.txt', chomp: false).and_return(command_result)

        command.call(O: 'order.txt')
      end
    end

    context 'with the :skip_to option' do
      it 'adds --skip-to=<file> to the command line' do
        expect_command_capturing('show', '--skip-to=file.rb', chomp: false).and_return(command_result)

        command.call(skip_to: 'file.rb')
      end
    end

    context 'with the :rotate_to option' do
      it 'adds --rotate-to=<file> to the command line' do
        expect_command_capturing('show', '--rotate-to=file.rb', chomp: false).and_return(command_result)

        command.call(rotate_to: 'file.rb')
      end
    end

    context 'with the :R option' do
      it 'adds -R to the command line' do
        expect_command_capturing('show', '-R', chomp: false).and_return(command_result)

        command.call(R: true)
      end
    end

    # Path scope options

    context 'with the :relative option' do
      it 'adds --relative to the command line when given true' do
        expect_command_capturing('show', '--relative', chomp: false).and_return(command_result)

        command.call(relative: true)
      end

      it 'adds --relative=<path> when given a string' do
        expect_command_capturing('show', '--relative=src/', chomp: false).and_return(command_result)

        command.call(relative: 'src/')
      end

      it 'adds --no-relative when negated' do
        expect_command_capturing('show', '--no-relative', chomp: false).and_return(command_result)

        command.call(relative: false)
      end
    end

    context 'with the :text option' do
      it 'adds --text to the command line' do
        expect_command_capturing('show', '--text', chomp: false).and_return(command_result)

        command.call(text: true)
      end

      it 'supports the :a alias' do
        expect_command_capturing('show', '--text', chomp: false).and_return(command_result)

        command.call(a: true)
      end
    end

    # Whitespace handling options

    context 'with the :ignore_cr_at_eol option' do
      it 'adds --ignore-cr-at-eol to the command line' do
        expect_command_capturing('show', '--ignore-cr-at-eol', chomp: false).and_return(command_result)

        command.call(ignore_cr_at_eol: true)
      end
    end

    context 'with the :ignore_space_at_eol option' do
      it 'adds --ignore-space-at-eol to the command line' do
        expect_command_capturing('show', '--ignore-space-at-eol', chomp: false).and_return(command_result)

        command.call(ignore_space_at_eol: true)
      end
    end

    context 'with the :ignore_space_change option' do
      it 'adds --ignore-space-change to the command line' do
        expect_command_capturing('show', '--ignore-space-change', chomp: false).and_return(command_result)

        command.call(ignore_space_change: true)
      end

      it 'supports the :b alias' do
        expect_command_capturing('show', '--ignore-space-change', chomp: false).and_return(command_result)

        command.call(b: true)
      end
    end

    context 'with the :ignore_all_space option' do
      it 'adds --ignore-all-space to the command line' do
        expect_command_capturing('show', '--ignore-all-space', chomp: false).and_return(command_result)

        command.call(ignore_all_space: true)
      end

      it 'supports the :w alias' do
        expect_command_capturing('show', '--ignore-all-space', chomp: false).and_return(command_result)

        command.call(w: true)
      end
    end

    context 'with the :ignore_blank_lines option' do
      it 'adds --ignore-blank-lines to the command line' do
        expect_command_capturing('show', '--ignore-blank-lines', chomp: false).and_return(command_result)

        command.call(ignore_blank_lines: true)
      end
    end

    context 'with the :ignore_matching_lines option' do
      it 'adds --ignore-matching-lines=<pattern> to the command line' do
        expect_command_capturing('show', '--ignore-matching-lines=^#', chomp: false).and_return(command_result)

        command.call(ignore_matching_lines: '^#')
      end

      it 'adds multiple --ignore-matching-lines flags when given an array' do
        expect_command_capturing('show', '--ignore-matching-lines=^#', '--ignore-matching-lines=^\s*$',
                                 chomp: false).and_return(command_result)

        command.call(ignore_matching_lines: ['^#', '^\s*$'])
      end

      it 'supports the :I alias' do
        expect_command_capturing('show', '--ignore-matching-lines=^#', chomp: false).and_return(command_result)

        command.call(I: '^#')
      end
    end

    context 'with the :inter_hunk_context option' do
      it 'adds --inter-hunk-context=<n> to the command line' do
        expect_command_capturing('show', '--inter-hunk-context=3', chomp: false).and_return(command_result)

        command.call(inter_hunk_context: 3)
      end
    end

    context 'with the :function_context option' do
      it 'adds --function-context to the command line' do
        expect_command_capturing('show', '--function-context', chomp: false).and_return(command_result)

        command.call(function_context: true)
      end

      it 'supports the :W alias' do
        expect_command_capturing('show', '--function-context', chomp: false).and_return(command_result)

        command.call(W: true)
      end
    end

    # Behavior control options

    context 'with the :ext_diff option' do
      it 'adds --ext-diff to the command line' do
        expect_command_capturing('show', '--ext-diff', chomp: false).and_return(command_result)

        command.call(ext_diff: true)
      end

      it 'adds --no-ext-diff when negated' do
        expect_command_capturing('show', '--no-ext-diff', chomp: false).and_return(command_result)

        command.call(ext_diff: false)
      end
    end

    context 'with the :textconv option' do
      it 'adds --textconv to the command line' do
        expect_command_capturing('show', '--textconv', chomp: false).and_return(command_result)

        command.call(textconv: true)
      end

      it 'adds --no-textconv when negated' do
        expect_command_capturing('show', '--no-textconv', chomp: false).and_return(command_result)

        command.call(textconv: false)
      end
    end

    context 'with the :ignore_submodules option' do
      it 'adds --ignore-submodules to the command line when given true' do
        expect_command_capturing('show', '--ignore-submodules', chomp: false).and_return(command_result)

        command.call(ignore_submodules: true)
      end

      it 'adds --ignore-submodules=<when> when given a string' do
        expect_command_capturing('show', '--ignore-submodules=all', chomp: false).and_return(command_result)

        command.call(ignore_submodules: 'all')
      end
    end

    # Prefix and path display options

    context 'with the :src_prefix option' do
      it 'adds --src-prefix=<prefix> to the command line' do
        expect_command_capturing('show', '--src-prefix=a/', chomp: false).and_return(command_result)

        command.call(src_prefix: 'a/')
      end
    end

    context 'with the :dst_prefix option' do
      it 'adds --dst-prefix=<prefix> to the command line' do
        expect_command_capturing('show', '--dst-prefix=b/', chomp: false).and_return(command_result)

        command.call(dst_prefix: 'b/')
      end
    end

    context 'with the :no_prefix option' do
      it 'adds --no-prefix to the command line' do
        expect_command_capturing('show', '--no-prefix', chomp: false).and_return(command_result)

        command.call(no_prefix: true)
      end
    end

    context 'with the :default_prefix option' do
      it 'adds --default-prefix to the command line' do
        expect_command_capturing('show', '--default-prefix', chomp: false).and_return(command_result)

        command.call(default_prefix: true)
      end
    end

    context 'with the :line_prefix option' do
      it 'adds --line-prefix=<prefix> to the command line' do
        expect_command_capturing('show', '--line-prefix=>> ', chomp: false).and_return(command_result)

        command.call(line_prefix: '>> ')
      end
    end

    context 'with the :ita_invisible_in_index option' do
      it 'adds --ita-invisible-in-index to the command line' do
        expect_command_capturing('show', '--ita-invisible-in-index', chomp: false).and_return(command_result)

        command.call(ita_invisible_in_index: true)
      end
    end

    context 'with the :ita_visible_in_index option' do
      it 'adds --ita-visible-in-index to the command line' do
        expect_command_capturing('show', '--ita-visible-in-index', chomp: false).and_return(command_result)

        command.call(ita_visible_in_index: true)
      end
    end

    context 'with the :max_depth option' do
      it 'adds --max-depth=<n> to the command line' do
        expect_command_capturing('show', '--max-depth=2', chomp: false).and_return(command_result)

        command.call(max_depth: '2')
      end
    end

    # Pathspec (tree objects only)

    context 'with the :pathspec option' do
      it 'adds -- and the pathspec entry after the object' do
        expect_command_capturing('show', 'HEAD^{tree}', '--', 'lib/', chomp: false).and_return(command_result)

        command.call('HEAD^{tree}', pathspec: ['lib/'])
      end

      it 'supports multiple pathspec entries' do
        expected_args = ['show', 'HEAD^{tree}', '--', 'lib/', 'README.md']
        expect_command_capturing(*expected_args, chomp: false).and_return(command_result)

        command.call('HEAD^{tree}', pathspec: ['lib/', 'README.md'])
      end

      it 'adds -- and pathspec when no object is given' do
        expect_command_capturing('show', '--', 'lib/', chomp: false).and_return(command_result)

        command.call(pathspec: ['lib/'])
      end

      it 'does not emit -- when no pathspec is given' do
        expect_command_capturing('show', 'HEAD^{tree}', chomp: false).and_return(command_result)

        command.call('HEAD^{tree}')
      end
    end

    # Execution option

    context 'with out: execution option (streaming)' do
      it 'dispatches to command_streaming when out: is given' do
        out_io = instance_double(File)
        expect_command_streaming('show', ':2:path/to/file.txt', out: out_io).and_return(command_result)

        command.call(':2:path/to/file.txt', out: out_io)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(foo: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
