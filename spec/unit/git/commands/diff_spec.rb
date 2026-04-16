# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff'

RSpec.describe Git::Commands::Diff do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  let(:numstat_output) do
    <<~OUTPUT
      5\t2\tlib/foo.rb
      3\t1\tlib/bar.rb
       2 files changed, 8 insertions(+), 3 deletions(-)
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments (working tree vs index)' do
      it 'runs git diff with no output-mode flags by default' do
        expected_result = command_result(numstat_output)
        expect_command_capturing('diff').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with output mode options' do
      it 'includes --patch when patch: true' do
        expect_command_capturing('diff', '--patch')
          .and_return(command_result(''))

        command.call(patch: true)
      end

      it 'includes --numstat when numstat: true' do
        expect_command_capturing('diff', '--numstat')
          .and_return(command_result(numstat_output))

        command.call(numstat: true)
      end

      it 'includes --raw when raw: true' do
        expect_command_capturing('diff', '--raw')
          .and_return(command_result(''))

        command.call(raw: true)
      end

      it 'includes --shortstat when shortstat: true' do
        expect_command_capturing('diff', '--shortstat')
          .and_return(command_result(''))

        command.call(shortstat: true)
      end

      it 'combines multiple output mode flags in DSL order' do
        expect_command_capturing('diff', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(numstat_output))

        command.call(patch: true, numstat: true, shortstat: true)
      end
    end

    context 'with prefix options (parser-contract args)' do
      it 'adds --src-prefix= when src_prefix: is given' do
        expect_command_capturing('diff', '--src-prefix=a/')
          .and_return(command_result(''))

        command.call(src_prefix: 'a/')
      end

      it 'adds --dst-prefix= when dst_prefix: is given' do
        expect_command_capturing('diff', '--dst-prefix=b/')
          .and_return(command_result(''))

        command.call(dst_prefix: 'b/')
      end

      it 'combines output mode flags with prefix options as facade would' do
        expect_command_capturing('diff', '--numstat', '--shortstat', '--src-prefix=a/', '--dst-prefix=b/')
          .and_return(command_result(numstat_output))

        command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with single commit (compare to HEAD)' do
      it 'passes the commit as an operand' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 'abc123').and_return(command_result(numstat_output))

        command.call('abc123', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with two commits (compare between commits)' do
      it 'passes both commits as operands' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', 'abc123',
                                 'def456').and_return(command_result(numstat_output))

        command.call('abc123', 'def456', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with three or more commits (combined diff of a merge commit)' do
      it 'passes all commits as operands' do
        expect_command_capturing('diff', '--merge-base', 'main', 'feature-a', 'feature-b')
          .and_return(command_result(''))

        command.call('main', 'feature-a', 'feature-b', merge_base: true)
      end
    end

    context 'with :cached option (staged changes)' do
      it 'includes the --cached flag' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 '--cached').and_return(command_result(numstat_output))

        command.call(cached: true, numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end

      it 'accepts :staged alias' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/',
                                 '--cached').and_return(command_result(numstat_output))

        command.call(staged: true, numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      end
    end

    context 'with :merge_base option' do
      it 'includes the --merge-base flag with a single commit operand' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--merge-base',
                                 'feature').and_return(command_result(numstat_output))

        command.call('feature', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', merge_base: true)
      end

      it 'places --merge-base before both commit operands' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--merge-base',
                                 'main', 'feature').and_return(command_result(numstat_output))

        command.call('main', 'feature', numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/',
                                        merge_base: true)
      end
    end

    context 'with :no_index option' do
      it 'passes paths via path: to emit -- separator' do
        expect_command_capturing('diff', '--patch', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--no-index',
                                 '--', '/path/a', '/path/b').and_return(command_result(''))

        command.call(patch: true, numstat: true, shortstat: true,
                     src_prefix: 'a/', dst_prefix: 'b/', no_index: true,
                     path: ['/path/a', '/path/b'])
      end

      it 'handles paths beginning with - safely via path:' do
        expect_command_capturing('diff', '--no-index', '--', '-weird-path', '/path/b')
          .and_return(command_result(''))

        command.call(no_index: true, path: ['-weird-path', '/path/b'])
      end
    end

    context 'with :path option' do
      it 'adds paths after the -- separator' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--src-prefix=a/', '--dst-prefix=b/', '--', 'lib/',
                                 'spec/').and_return(command_result(numstat_output))

        command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', path: ['lib/', 'spec/'])
      end
    end

    context 'with :dirstat option' do
      let(:dirstat_output) do
        <<~OUTPUT
          5\t2\tlib/foo.rb
          3\t1\tlib/bar.rb
           2 files changed, 8 insertions(+), 3 deletions(-)
            62.5% lib/
        OUTPUT
      end

      it 'includes the --dirstat flag when true' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--dirstat',
                                 '--src-prefix=a/', '--dst-prefix=b/').and_return(command_result(dirstat_output))

        result = command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', dirstat: true)

        expect(result.stdout).to include('62.5% lib/')
      end

      it 'passes dirstat options as an inline value' do
        expect_command_capturing('diff', '--numstat', '--shortstat',
                                 '--dirstat=lines,cumulative',
                                 '--src-prefix=a/', '--dst-prefix=b/').and_return(command_result(dirstat_output))

        command.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/', dirstat: 'lines,cumulative')
      end
    end

    context 'with :p alias' do
      it 'emits --patch' do
        expect_command_capturing('diff', '--patch').and_return(command_result(''))
        command.call(p: true)
      end
    end

    context 'with :u alias' do
      it 'emits --patch' do
        expect_command_capturing('diff', '--patch').and_return(command_result(''))
        command.call(u: true)
      end
    end

    context 'with :no_patch option' do
      it 'includes --no-patch when true' do
        expect_command_capturing('diff', '--no-patch').and_return(command_result(''))
        command.call(no_patch: true)
      end
    end

    context 'with :s alias' do
      it 'emits --no-patch' do
        expect_command_capturing('diff', '--no-patch').and_return(command_result(''))
        command.call(s: true)
      end
    end

    context 'with :unified option' do
      it 'includes --unified=<n> when given' do
        expect_command_capturing('diff', '--unified=5').and_return(command_result(''))
        command.call(unified: 5)
      end
    end

    context 'with :U alias' do
      it 'emits --unified=<n>' do
        expect_command_capturing('diff', '--unified=3').and_return(command_result(''))
        command.call(U: 3)
      end
    end

    context 'with :output option' do
      it 'includes --output=<file>' do
        expect_command_capturing('diff', '--output=/tmp/out.diff').and_return(command_result(''))
        command.call(output: '/tmp/out.diff')
      end
    end

    context 'with :output_indicator_new option' do
      it 'includes --output-indicator-new=<char>' do
        expect_command_capturing('diff', '--output-indicator-new=+').and_return(command_result(''))
        command.call(output_indicator_new: '+')
      end
    end

    context 'with :output_indicator_old option' do
      it 'includes --output-indicator-old=<char>' do
        expect_command_capturing('diff', '--output-indicator-old=-').and_return(command_result(''))
        command.call(output_indicator_old: '-')
      end
    end

    context 'with :output_indicator_context option' do
      it 'includes --output-indicator-context=<char>' do
        expect_command_capturing('diff', '--output-indicator-context= ').and_return(command_result(''))
        command.call(output_indicator_context: ' ')
      end
    end

    context 'with :patch_with_raw option' do
      it 'includes --patch-with-raw' do
        expect_command_capturing('diff', '--patch-with-raw').and_return(command_result(''))
        command.call(patch_with_raw: true)
      end
    end

    context 'with :indent_heuristic option' do
      it 'includes --indent-heuristic when true' do
        expect_command_capturing('diff', '--indent-heuristic').and_return(command_result(''))
        command.call(indent_heuristic: true)
      end

      it 'includes --no-indent-heuristic when false' do
        expect_command_capturing('diff', '--no-indent-heuristic').and_return(command_result(''))
        command.call(indent_heuristic: false)
      end
    end

    context 'with :minimal option' do
      it 'includes --minimal' do
        expect_command_capturing('diff', '--minimal').and_return(command_result(''))
        command.call(minimal: true)
      end
    end

    context 'with :patience option' do
      it 'includes --patience' do
        expect_command_capturing('diff', '--patience').and_return(command_result(''))
        command.call(patience: true)
      end
    end

    context 'with :histogram option' do
      it 'includes --histogram' do
        expect_command_capturing('diff', '--histogram').and_return(command_result(''))
        command.call(histogram: true)
      end
    end

    context 'with :anchored option' do
      it 'includes --anchored=<text>' do
        expect_command_capturing('diff', '--anchored=foo').and_return(command_result(''))
        command.call(anchored: 'foo')
      end

      it 'repeats --anchored for each value in an array' do
        expect_command_capturing('diff', '--anchored=foo', '--anchored=bar')
          .and_return(command_result(''))
        command.call(anchored: %w[foo bar])
      end
    end

    context 'with :diff_algorithm option' do
      it 'includes --diff-algorithm=<algorithm>' do
        expect_command_capturing('diff', '--diff-algorithm=patience').and_return(command_result(''))
        command.call(diff_algorithm: 'patience')
      end
    end

    context 'with :stat option' do
      it 'includes bare --stat when true' do
        expect_command_capturing('diff', '--stat').and_return(command_result(''))
        command.call(stat: true)
      end

      it 'includes --stat=<params> when given a string' do
        expect_command_capturing('diff', '--stat=100,40,10').and_return(command_result(''))
        command.call(stat: '100,40,10')
      end
    end

    context 'with :stat sub-options' do
      it 'includes --stat-width=<n>' do
        expect_command_capturing('diff', '--stat-width=100').and_return(command_result(''))
        command.call(stat_width: 100)
      end

      it 'includes --stat-name-width=<n>' do
        expect_command_capturing('diff', '--stat-name-width=40').and_return(command_result(''))
        command.call(stat_name_width: 40)
      end

      it 'includes --stat-count=<n>' do
        expect_command_capturing('diff', '--stat-count=10').and_return(command_result(''))
        command.call(stat_count: 10)
      end

      it 'includes --stat-graph-width=<n>' do
        expect_command_capturing('diff', '--stat-graph-width=20').and_return(command_result(''))
        command.call(stat_graph_width: 20)
      end
    end

    context 'with :compact_summary option' do
      it 'includes --compact-summary' do
        expect_command_capturing('diff', '--compact-summary').and_return(command_result(''))
        command.call(compact_summary: true)
      end
    end

    context 'with :X alias for dirstat' do
      it 'emits --dirstat' do
        expect_command_capturing('diff', '--dirstat').and_return(command_result(''))
        command.call(X: true)
      end
    end

    context 'with :cumulative option' do
      it 'includes --cumulative' do
        expect_command_capturing('diff', '--cumulative').and_return(command_result(''))
        command.call(cumulative: true)
      end
    end

    context 'with :dirstat_by_file option' do
      it 'includes bare --dirstat-by-file when true' do
        expect_command_capturing('diff', '--dirstat-by-file').and_return(command_result(''))
        command.call(dirstat_by_file: true)
      end

      it 'includes --dirstat-by-file=<params> when given a string' do
        expect_command_capturing('diff', '--dirstat-by-file=cumulative').and_return(command_result(''))
        command.call(dirstat_by_file: 'cumulative')
      end
    end

    context 'with :summary option' do
      it 'includes --summary' do
        expect_command_capturing('diff', '--summary').and_return(command_result(''))
        command.call(summary: true)
      end
    end

    context 'with :patch_with_stat option' do
      it 'includes --patch-with-stat' do
        expect_command_capturing('diff', '--patch-with-stat').and_return(command_result(''))
        command.call(patch_with_stat: true)
      end
    end

    context 'with :z option' do
      it 'includes -z' do
        expect_command_capturing('diff', '-z').and_return(command_result(''))
        command.call(z: true)
      end
    end

    context 'with :name_only option' do
      it 'includes --name-only' do
        expect_command_capturing('diff', '--name-only').and_return(command_result(''))
        command.call(name_only: true)
      end
    end

    context 'with :name_status option' do
      it 'includes --name-status' do
        expect_command_capturing('diff', '--name-status').and_return(command_result(''))
        command.call(name_status: true)
      end
    end

    context 'with :submodule option' do
      it 'includes bare --submodule when true' do
        expect_command_capturing('diff', '--submodule').and_return(command_result(''))
        command.call(submodule: true)
      end

      it 'includes --submodule=<format> when given a string' do
        expect_command_capturing('diff', '--submodule=log').and_return(command_result(''))
        command.call(submodule: 'log')
      end
    end

    context 'with :color option' do
      it 'includes --color when true' do
        expect_command_capturing('diff', '--color').and_return(command_result(''))
        command.call(color: true)
      end

      it 'includes --color=<when> when given a string' do
        expect_command_capturing('diff', '--color=always').and_return(command_result(''))
        command.call(color: 'always')
      end

      it 'includes --no-color when false' do
        expect_command_capturing('diff', '--no-color').and_return(command_result(''))
        command.call(color: false)
      end
    end

    context 'with :color_moved option' do
      it 'includes --color-moved when true' do
        expect_command_capturing('diff', '--color-moved').and_return(command_result(''))
        command.call(color_moved: true)
      end

      it 'includes --color-moved=<mode> when given a string' do
        expect_command_capturing('diff', '--color-moved=zebra').and_return(command_result(''))
        command.call(color_moved: 'zebra')
      end

      it 'includes --no-color-moved when false' do
        expect_command_capturing('diff', '--no-color-moved').and_return(command_result(''))
        command.call(color_moved: false)
      end
    end

    context 'with :color_moved_ws option' do
      it 'includes --color-moved-ws when true' do
        expect_command_capturing('diff', '--color-moved-ws').and_return(command_result(''))
        command.call(color_moved_ws: true)
      end

      it 'includes --color-moved-ws=<mode> when given a string' do
        expect_command_capturing('diff', '--color-moved-ws=ignore-all-space')
          .and_return(command_result(''))
        command.call(color_moved_ws: 'ignore-all-space')
      end

      it 'includes --no-color-moved-ws when false' do
        expect_command_capturing('diff', '--no-color-moved-ws').and_return(command_result(''))
        command.call(color_moved_ws: false)
      end
    end

    context 'with :word_diff option' do
      it 'includes bare --word-diff when true' do
        expect_command_capturing('diff', '--word-diff').and_return(command_result(''))
        command.call(word_diff: true)
      end

      it 'includes --word-diff=<mode> when given a string' do
        expect_command_capturing('diff', '--word-diff=color').and_return(command_result(''))
        command.call(word_diff: 'color')
      end
    end

    context 'with :word_diff_regex option' do
      it 'includes --word-diff-regex=<regex>' do
        expect_command_capturing('diff', '--word-diff-regex=\\w+').and_return(command_result(''))
        command.call(word_diff_regex: '\\w+')
      end
    end

    context 'with :color_words option' do
      it 'includes bare --color-words when true' do
        expect_command_capturing('diff', '--color-words').and_return(command_result(''))
        command.call(color_words: true)
      end

      it 'includes --color-words=<regex> when given a string' do
        expect_command_capturing('diff', '--color-words=\\w+').and_return(command_result(''))
        command.call(color_words: '\\w+')
      end
    end

    context 'with :no_renames option' do
      it 'includes --no-renames' do
        expect_command_capturing('diff', '--no-renames').and_return(command_result(''))
        command.call(no_renames: true)
      end
    end

    context 'with :rename_empty option' do
      it 'includes --rename-empty when true' do
        expect_command_capturing('diff', '--rename-empty').and_return(command_result(''))
        command.call(rename_empty: true)
      end

      it 'includes --no-rename-empty when false' do
        expect_command_capturing('diff', '--no-rename-empty').and_return(command_result(''))
        command.call(rename_empty: false)
      end
    end

    context 'with :check option' do
      it 'includes --check' do
        expect_command_capturing('diff', '--check').and_return(command_result(''))
        command.call(check: true)
      end
    end

    context 'with :ws_error_highlight option' do
      it 'includes --ws-error-highlight=<kind>' do
        expect_command_capturing('diff', '--ws-error-highlight=old,new').and_return(command_result(''))
        command.call(ws_error_highlight: 'old,new')
      end
    end

    context 'with :full_index option' do
      it 'includes --full-index' do
        expect_command_capturing('diff', '--full-index').and_return(command_result(''))
        command.call(full_index: true)
      end
    end

    context 'with :binary option' do
      it 'includes --binary' do
        expect_command_capturing('diff', '--binary').and_return(command_result(''))
        command.call(binary: true)
      end
    end

    context 'with :abbrev option' do
      it 'includes bare --abbrev when true' do
        expect_command_capturing('diff', '--abbrev').and_return(command_result(''))
        command.call(abbrev: true)
      end

      it 'includes --abbrev=<n> when given a string' do
        expect_command_capturing('diff', '--abbrev=10').and_return(command_result(''))
        command.call(abbrev: '10')
      end
    end

    context 'with :break_rewrites option' do
      it 'includes bare --break-rewrites when true' do
        expect_command_capturing('diff', '--break-rewrites').and_return(command_result(''))
        command.call(break_rewrites: true)
      end

      it 'includes --break-rewrites=<n>/<m> when given a string' do
        expect_command_capturing('diff', '--break-rewrites=50/60').and_return(command_result(''))
        command.call(break_rewrites: '50/60')
      end
    end

    context 'with :B alias for break_rewrites' do
      it 'emits --break-rewrites' do
        expect_command_capturing('diff', '--break-rewrites').and_return(command_result(''))
        command.call(B: true)
      end
    end

    context 'with :find_renames option' do
      it 'includes bare --find-renames when true' do
        expect_command_capturing('diff', '--find-renames').and_return(command_result(''))
        command.call(find_renames: true)
      end

      it 'includes --find-renames=<n> when given a string' do
        expect_command_capturing('diff', '--find-renames=50').and_return(command_result(''))
        command.call(find_renames: '50')
      end
    end

    context 'with :M alias for find_renames' do
      it 'emits --find-renames' do
        expect_command_capturing('diff', '--find-renames').and_return(command_result(''))
        command.call(M: true)
      end
    end

    context 'with :find_copies option' do
      it 'includes bare --find-copies when true' do
        expect_command_capturing('diff', '--find-copies').and_return(command_result(''))
        command.call(find_copies: true)
      end

      it 'includes --find-copies=<n> when given a string' do
        expect_command_capturing('diff', '--find-copies=75').and_return(command_result(''))
        command.call(find_copies: '75')
      end
    end

    context 'with :C alias for find_copies' do
      it 'emits --find-copies' do
        expect_command_capturing('diff', '--find-copies').and_return(command_result(''))
        command.call(C: true)
      end
    end

    context 'with :find_copies_harder option' do
      it 'includes --find-copies-harder' do
        expect_command_capturing('diff', '--find-copies-harder').and_return(command_result(''))
        command.call(find_copies_harder: true)
      end
    end

    context 'with :irreversible_delete option' do
      it 'includes --irreversible-delete' do
        expect_command_capturing('diff', '--irreversible-delete').and_return(command_result(''))
        command.call(irreversible_delete: true)
      end
    end

    context 'with :D alias for irreversible_delete' do
      it 'emits --irreversible-delete' do
        expect_command_capturing('diff', '--irreversible-delete').and_return(command_result(''))
        command.call(D: true)
      end
    end

    context 'with :l option' do
      it 'includes -l<num>' do
        expect_command_capturing('diff', '-l1000').and_return(command_result(''))
        command.call(l: 1000)
      end
    end

    context 'with :diff_filter option' do
      it 'includes --diff-filter=<filter>' do
        expect_command_capturing('diff', '--diff-filter=ACDM').and_return(command_result(''))
        command.call(diff_filter: 'ACDM')
      end
    end

    context 'with :S option' do
      it 'includes -S<string>' do
        expect_command_capturing('diff', '-Ssearch_term').and_return(command_result(''))
        command.call(S: 'search_term')
      end
    end

    context 'with :G option' do
      it 'includes -G<regex>' do
        expect_command_capturing('diff', '-Gpattern').and_return(command_result(''))
        command.call(G: 'pattern')
      end
    end

    context 'with :find_object option' do
      it 'includes --find-object=<id>' do
        expect_command_capturing('diff', '--find-object=abc123').and_return(command_result(''))
        command.call(find_object: 'abc123')
      end
    end

    context 'with :pickaxe_all option' do
      it 'includes --pickaxe-all' do
        expect_command_capturing('diff', '--pickaxe-all').and_return(command_result(''))
        command.call(pickaxe_all: true)
      end
    end

    context 'with :pickaxe_regex option' do
      it 'includes --pickaxe-regex' do
        expect_command_capturing('diff', '--pickaxe-regex').and_return(command_result(''))
        command.call(pickaxe_regex: true)
      end
    end

    context 'with :O option' do
      it 'includes -O<orderfile>' do
        expect_command_capturing('diff', '-O/tmp/order').and_return(command_result(''))
        command.call(O: '/tmp/order')
      end
    end

    context 'with :skip_to option' do
      it 'includes --skip-to=<file>' do
        expect_command_capturing('diff', '--skip-to=lib/foo.rb').and_return(command_result(''))
        command.call(skip_to: 'lib/foo.rb')
      end
    end

    context 'with :rotate_to option' do
      it 'includes --rotate-to=<file>' do
        expect_command_capturing('diff', '--rotate-to=lib/foo.rb').and_return(command_result(''))
        command.call(rotate_to: 'lib/foo.rb')
      end
    end

    context 'with :R option' do
      it 'includes -R' do
        expect_command_capturing('diff', '-R').and_return(command_result(''))
        command.call(R: true)
      end
    end

    context 'with :relative option' do
      it 'includes bare --relative when true' do
        expect_command_capturing('diff', '--relative').and_return(command_result(''))
        command.call(relative: true)
      end

      it 'includes --relative=<path> when given a string' do
        expect_command_capturing('diff', '--relative=lib/').and_return(command_result(''))
        command.call(relative: 'lib/')
      end

      it 'includes --no-relative when false' do
        expect_command_capturing('diff', '--no-relative').and_return(command_result(''))
        command.call(relative: false)
      end
    end

    context 'with :text option' do
      it 'includes --text' do
        expect_command_capturing('diff', '--text').and_return(command_result(''))
        command.call(text: true)
      end
    end

    context 'with :a alias for text' do
      it 'emits --text' do
        expect_command_capturing('diff', '--text').and_return(command_result(''))
        command.call(a: true)
      end
    end

    context 'with :ignore_cr_at_eol option' do
      it 'includes --ignore-cr-at-eol' do
        expect_command_capturing('diff', '--ignore-cr-at-eol').and_return(command_result(''))
        command.call(ignore_cr_at_eol: true)
      end
    end

    context 'with :ignore_space_at_eol option' do
      it 'includes --ignore-space-at-eol' do
        expect_command_capturing('diff', '--ignore-space-at-eol').and_return(command_result(''))
        command.call(ignore_space_at_eol: true)
      end
    end

    context 'with :ignore_space_change option' do
      it 'includes --ignore-space-change' do
        expect_command_capturing('diff', '--ignore-space-change').and_return(command_result(''))
        command.call(ignore_space_change: true)
      end
    end

    context 'with :b alias for ignore_space_change' do
      it 'emits --ignore-space-change' do
        expect_command_capturing('diff', '--ignore-space-change').and_return(command_result(''))
        command.call(b: true)
      end
    end

    context 'with :ignore_all_space option' do
      it 'includes --ignore-all-space' do
        expect_command_capturing('diff', '--ignore-all-space').and_return(command_result(''))
        command.call(ignore_all_space: true)
      end
    end

    context 'with :w alias for ignore_all_space' do
      it 'emits --ignore-all-space' do
        expect_command_capturing('diff', '--ignore-all-space').and_return(command_result(''))
        command.call(w: true)
      end
    end

    context 'with :ignore_blank_lines option' do
      it 'includes --ignore-blank-lines' do
        expect_command_capturing('diff', '--ignore-blank-lines').and_return(command_result(''))
        command.call(ignore_blank_lines: true)
      end
    end

    context 'with :ignore_matching_lines option' do
      it 'includes --ignore-matching-lines=<regex>' do
        expect_command_capturing('diff', '--ignore-matching-lines=^#').and_return(command_result(''))
        command.call(ignore_matching_lines: '^#')
      end

      it 'repeats for each value in an array' do
        expect_command_capturing('diff', '--ignore-matching-lines=^#', '--ignore-matching-lines=^//')
          .and_return(command_result(''))
        command.call(ignore_matching_lines: ['^#', '^//'])
      end
    end

    context 'with :I alias for ignore_matching_lines' do
      it 'emits --ignore-matching-lines=<regex>' do
        expect_command_capturing('diff', '--ignore-matching-lines=^#').and_return(command_result(''))
        command.call(I: '^#')
      end
    end

    context 'with :inter_hunk_context option' do
      it 'includes --inter-hunk-context=<n>' do
        expect_command_capturing('diff', '--inter-hunk-context=5').and_return(command_result(''))
        command.call(inter_hunk_context: 5)
      end
    end

    context 'with :function_context option' do
      it 'includes --function-context' do
        expect_command_capturing('diff', '--function-context').and_return(command_result(''))
        command.call(function_context: true)
      end
    end

    context 'with :W alias for function_context' do
      it 'emits --function-context' do
        expect_command_capturing('diff', '--function-context').and_return(command_result(''))
        command.call(W: true)
      end
    end

    context 'with :exit_code option' do
      it 'includes --exit-code' do
        expect_command_capturing('diff', '--exit-code').and_return(command_result(''))
        command.call(exit_code: true)
      end
    end

    context 'with :quiet option' do
      it 'includes --quiet' do
        expect_command_capturing('diff', '--quiet').and_return(command_result(''))
        command.call(quiet: true)
      end
    end

    context 'with :ext_diff option' do
      it 'includes --ext-diff when true' do
        expect_command_capturing('diff', '--ext-diff').and_return(command_result(''))
        command.call(ext_diff: true)
      end

      it 'includes --no-ext-diff when false' do
        expect_command_capturing('diff', '--no-ext-diff').and_return(command_result(''))
        command.call(ext_diff: false)
      end
    end

    context 'with :textconv option' do
      it 'includes --textconv when true' do
        expect_command_capturing('diff', '--textconv').and_return(command_result(''))
        command.call(textconv: true)
      end

      it 'includes --no-textconv when false' do
        expect_command_capturing('diff', '--no-textconv').and_return(command_result(''))
        command.call(textconv: false)
      end
    end

    context 'with :ignore_submodules option' do
      it 'includes bare --ignore-submodules when true' do
        expect_command_capturing('diff', '--ignore-submodules').and_return(command_result(''))
        command.call(ignore_submodules: true)
      end

      it 'includes --ignore-submodules=<when> when given a string' do
        expect_command_capturing('diff', '--ignore-submodules=all').and_return(command_result(''))
        command.call(ignore_submodules: 'all')
      end
    end

    context 'with :no_prefix option' do
      it 'includes --no-prefix' do
        expect_command_capturing('diff', '--no-prefix').and_return(command_result(''))
        command.call(no_prefix: true)
      end
    end

    context 'with :default_prefix option' do
      it 'includes --default-prefix' do
        expect_command_capturing('diff', '--default-prefix').and_return(command_result(''))
        command.call(default_prefix: true)
      end
    end

    context 'with :line_prefix option' do
      it 'includes --line-prefix=<prefix>' do
        expect_command_capturing('diff', '--line-prefix=>>> ').and_return(command_result(''))
        command.call(line_prefix: '>>> ')
      end
    end

    context 'with :ita_invisible_in_index option' do
      it 'includes --ita-invisible-in-index' do
        expect_command_capturing('diff', '--ita-invisible-in-index').and_return(command_result(''))
        command.call(ita_invisible_in_index: true)
      end
    end

    context 'with :ita_visible_in_index option' do
      it 'includes --ita-visible-in-index' do
        expect_command_capturing('diff', '--ita-visible-in-index').and_return(command_result(''))
        command.call(ita_visible_in_index: true)
      end
    end

    context 'with :max_depth option' do
      it 'includes --max-depth=<n>' do
        expect_command_capturing('diff', '--max-depth=2').and_return(command_result(''))
        command.call(max_depth: 2)
      end
    end

    context 'with :c option (combined diff format)' do
      it 'includes -c' do
        expect_command_capturing('diff', '-c').and_return(command_result(''))
        command.call(c: true)
      end
    end

    context 'with :cc option (dense combined diff format)' do
      it 'includes --cc' do
        expect_command_capturing('diff', '--cc').and_return(command_result(''))
        command.call(cc: true)
      end
    end

    context 'with :combined_all_paths option' do
      it 'includes --combined-all-paths' do
        expect_command_capturing('diff', '--combined-all-paths').and_return(command_result(''))
        command.call(combined_all_paths: true)
      end
    end

    context 'with :base option (merge conflict stage)' do
      it 'includes --base' do
        expect_command_capturing('diff', '--base').and_return(command_result(''))
        command.call(base: true)
      end
    end

    context 'with :"1" alias for base' do
      it 'emits --base' do
        expect_command_capturing('diff', '--base').and_return(command_result(''))
        command.call('1': true)
      end
    end

    context 'with :ours option (merge conflict stage)' do
      it 'includes --ours' do
        expect_command_capturing('diff', '--ours').and_return(command_result(''))
        command.call(ours: true)
      end
    end

    context 'with :"2" alias for ours' do
      it 'emits --ours' do
        expect_command_capturing('diff', '--ours').and_return(command_result(''))
        command.call('2': true)
      end
    end

    context 'with :theirs option (merge conflict stage)' do
      it 'includes --theirs' do
        expect_command_capturing('diff', '--theirs').and_return(command_result(''))
        command.call(theirs: true)
      end
    end

    context 'with :"3" alias for theirs' do
      it 'emits --theirs' do
        expect_command_capturing('diff', '--theirs').and_return(command_result(''))
        command.call('3': true)
      end
    end

    context 'with :"0" option' do
      it 'includes -0' do
        expect_command_capturing('diff', '-0').and_return(command_result(''))
        command.call('0': true)
      end
    end

    context 'exit code handling' do
      it 'returns successfully with exit code 0' do
        expect_command_capturing('diff').and_return(command_result('', exitstatus: 0))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns successfully with exit code 1' do
        expect_command_capturing('diff').and_return(command_result(numstat_output, exitstatus: 1))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError with exit code 2' do
        expect_command_capturing('diff')
          .and_return(command_result('', stderr: 'fatal: bad revision', exitstatus: 2))

        expect { command.call }
          .to raise_error(Git::FailedError, /bad revision/)
      end
    end
  end
end
