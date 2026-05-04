# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/log'

RSpec.describe Git::Commands::Log do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git log with no output-format flags by default' do
        expected_result = command_result
        expect_command_capturing('log').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    # Commit Limiting

    context 'with the :max_count option' do
      it 'includes --max-count=<n>' do
        expect_command_capturing('log', '--max-count=10').and_return(command_result)

        command.call(max_count: 10)
      end

      it 'accepts :n as an alias for :max_count' do
        expect_command_capturing('log', '--max-count=5').and_return(command_result)

        command.call(n: 5)
      end
    end

    context 'with the :skip option' do
      it 'includes --skip=<n>' do
        expect_command_capturing('log', '--skip=5').and_return(command_result)

        command.call(skip: 5)
      end
    end

    context 'with the :since option' do
      it 'includes --since=<value>' do
        expect_command_capturing('log', '--since=1 week ago').and_return(command_result)

        command.call(since: '1 week ago')
      end
    end

    context 'with the :after option' do
      it 'includes --after=<value>' do
        expect_command_capturing('log', '--after=2024-01-01').and_return(command_result)

        command.call(after: '2024-01-01')
      end
    end

    context 'with the :since_as_filter option' do
      it 'includes --since-as-filter=<value>' do
        expect_command_capturing('log', '--since-as-filter=2024-01-01').and_return(command_result)

        command.call(since_as_filter: '2024-01-01')
      end
    end

    context 'with the :until option' do
      it 'includes --until=<value>' do
        expect_command_capturing('log', '--until=2024-01-01').and_return(command_result)

        command.call(until: '2024-01-01')
      end
    end

    context 'with the :before option' do
      it 'includes --before=<value>' do
        expect_command_capturing('log', '--before=2024-06-01').and_return(command_result)

        command.call(before: '2024-06-01')
      end
    end

    context 'with the :author option' do
      it 'includes --author=<value>' do
        expect_command_capturing('log', '--author=Jane Doe').and_return(command_result)

        command.call(author: 'Jane Doe')
      end
    end

    context 'with the :committer option' do
      it 'includes --committer=<value>' do
        expect_command_capturing('log', '--committer=Jane Doe').and_return(command_result)

        command.call(committer: 'Jane Doe')
      end
    end

    context 'with the :grep_reflog option' do
      it 'includes --grep-reflog=<value>' do
        expect_command_capturing('log', '--grep-reflog=HEAD@{1}').and_return(command_result)

        command.call(grep_reflog: 'HEAD@{1}')
      end
    end

    context 'with the :grep option' do
      it 'includes --grep=<value>' do
        expect_command_capturing('log', '--grep=fix bug').and_return(command_result)

        command.call(grep: 'fix bug')
      end
    end

    context 'with the :all_match option' do
      it 'includes the --all-match flag' do
        expect_command_capturing('log', '--all-match').and_return(command_result)

        command.call(all_match: true)
      end
    end

    context 'with the :invert_grep option' do
      it 'includes the --invert-grep flag' do
        expect_command_capturing('log', '--invert-grep').and_return(command_result)

        command.call(invert_grep: true)
      end
    end

    context 'with the :regexp_ignore_case option' do
      it 'includes the --regexp-ignore-case flag' do
        expect_command_capturing('log', '--regexp-ignore-case').and_return(command_result)

        command.call(regexp_ignore_case: true)
      end

      it 'accepts :i as an alias for :regexp_ignore_case' do
        expect_command_capturing('log', '--regexp-ignore-case').and_return(command_result)

        command.call(i: true)
      end
    end

    context 'with the :basic_regexp option' do
      it 'includes the --basic-regexp flag' do
        expect_command_capturing('log', '--basic-regexp').and_return(command_result)

        command.call(basic_regexp: true)
      end
    end

    context 'with the :extended_regexp option' do
      it 'includes the --extended-regexp flag' do
        expect_command_capturing('log', '--extended-regexp').and_return(command_result)

        command.call(extended_regexp: true)
      end

      it 'accepts :E as an alias for :extended_regexp' do
        expect_command_capturing('log', '--extended-regexp').and_return(command_result)

        command.call(E: true)
      end
    end

    context 'with the :fixed_strings option' do
      it 'includes the --fixed-strings flag' do
        expect_command_capturing('log', '--fixed-strings').and_return(command_result)

        command.call(fixed_strings: true)
      end

      it 'accepts :F as an alias for :fixed_strings' do
        expect_command_capturing('log', '--fixed-strings').and_return(command_result)

        command.call(F: true)
      end
    end

    context 'with the :perl_regexp option' do
      it 'includes the --perl-regexp flag' do
        expect_command_capturing('log', '--perl-regexp').and_return(command_result)

        command.call(perl_regexp: true)
      end

      it 'accepts :P as an alias for :perl_regexp' do
        expect_command_capturing('log', '--perl-regexp').and_return(command_result)

        command.call(P: true)
      end
    end

    context 'with the :remove_empty option' do
      it 'includes the --remove-empty flag' do
        expect_command_capturing('log', '--remove-empty').and_return(command_result)

        command.call(remove_empty: true)
      end
    end

    context 'with the :merges option' do
      it 'includes the --merges flag' do
        expect_command_capturing('log', '--merges').and_return(command_result)

        command.call(merges: true)
      end

      context 'when :no_merges is true' do
        it 'includes the --no-merges flag' do
          expect_command_capturing('log', '--no-merges').and_return(command_result)

          command.call(no_merges: true)
        end
      end
    end

    context 'with the :min_parents option' do
      it 'includes --min-parents=<n>' do
        expect_command_capturing('log', '--min-parents=2').and_return(command_result)

        command.call(min_parents: 2)
      end
    end

    context 'with the :max_parents option' do
      it 'includes --max-parents=<n>' do
        expect_command_capturing('log', '--max-parents=1').and_return(command_result)

        command.call(max_parents: 1)
      end
    end

    context 'with the :first_parent option' do
      it 'includes the --first-parent flag' do
        expect_command_capturing('log', '--first-parent').and_return(command_result)

        command.call(first_parent: true)
      end
    end

    context 'with the :exclude_first_parent_only option' do
      it 'includes the --exclude-first-parent-only flag' do
        expect_command_capturing('log', '--exclude-first-parent-only').and_return(command_result)

        command.call(exclude_first_parent_only: true)
      end
    end

    context 'with the :all option' do
      it 'includes the --all flag' do
        expect_command_capturing('log', '--all').and_return(command_result)

        command.call(all: true)
      end
    end

    context 'with the :branches option' do
      it 'includes the bare --branches flag when true' do
        expect_command_capturing('log', '--branches').and_return(command_result)

        command.call(branches: true)
      end

      it 'includes --branches=<pattern> when a pattern is given' do
        expect_command_capturing('log', '--branches=feature*').and_return(command_result)

        command.call(branches: 'feature*')
      end
    end

    context 'with the :tags option' do
      it 'includes the bare --tags flag when true' do
        expect_command_capturing('log', '--tags').and_return(command_result)

        command.call(tags: true)
      end

      it 'includes --tags=<pattern> when a pattern is given' do
        expect_command_capturing('log', '--tags=v*').and_return(command_result)

        command.call(tags: 'v*')
      end
    end

    context 'with the :remotes option' do
      it 'includes the bare --remotes flag when true' do
        expect_command_capturing('log', '--remotes').and_return(command_result)

        command.call(remotes: true)
      end

      it 'includes --remotes=<pattern> when a pattern is given' do
        expect_command_capturing('log', '--remotes=origin/*').and_return(command_result)

        command.call(remotes: 'origin/*')
      end
    end

    context 'with the :glob option' do
      it 'includes --glob=<value>' do
        expect_command_capturing('log', '--glob=refs/heads/feature*').and_return(command_result)

        command.call(glob: 'refs/heads/feature*')
      end
    end

    context 'with the :exclude option' do
      it 'includes --exclude=<value>' do
        expect_command_capturing('log', '--exclude=refs/heads/tmp/*').and_return(command_result)

        command.call(exclude: 'refs/heads/tmp/*')
      end
    end

    context 'with the :exclude_hidden option' do
      it 'includes --exclude-hidden=<value>' do
        expect_command_capturing('log', '--exclude-hidden=fetch').and_return(command_result)

        command.call(exclude_hidden: 'fetch')
      end
    end

    context 'with the :reflog option' do
      it 'includes the --reflog flag' do
        expect_command_capturing('log', '--reflog').and_return(command_result)

        command.call(reflog: true)
      end
    end

    context 'with the :alternate_refs option' do
      it 'includes the --alternate-refs flag' do
        expect_command_capturing('log', '--alternate-refs').and_return(command_result)

        command.call(alternate_refs: true)
      end
    end

    context 'with the :single_worktree option' do
      it 'includes the --single-worktree flag' do
        expect_command_capturing('log', '--single-worktree').and_return(command_result)

        command.call(single_worktree: true)
      end
    end

    context 'with the :ignore_missing option' do
      it 'includes the --ignore-missing flag' do
        expect_command_capturing('log', '--ignore-missing').and_return(command_result)

        command.call(ignore_missing: true)
      end
    end

    context 'with the :bisect option' do
      it 'includes the --bisect flag' do
        expect_command_capturing('log', '--bisect').and_return(command_result)

        command.call(bisect: true)
      end
    end

    context 'with the :cherry_mark option' do
      it 'includes the --cherry-mark flag' do
        expect_command_capturing('log', '--cherry-mark').and_return(command_result)

        command.call(cherry_mark: true)
      end
    end

    context 'with the :cherry_pick option' do
      it 'includes the --cherry-pick flag' do
        expect_command_capturing('log', '--cherry-pick').and_return(command_result)

        command.call(cherry_pick: true)
      end
    end

    context 'with the :left_only option' do
      it 'includes the --left-only flag' do
        expect_command_capturing('log', '--left-only').and_return(command_result)

        command.call(left_only: true)
      end
    end

    context 'with the :right_only option' do
      it 'includes the --right-only flag' do
        expect_command_capturing('log', '--right-only').and_return(command_result)

        command.call(right_only: true)
      end
    end

    context 'with the :cherry option' do
      it 'includes the --cherry flag' do
        expect_command_capturing('log', '--cherry').and_return(command_result)

        command.call(cherry: true)
      end
    end

    context 'with the :walk_reflogs option' do
      it 'includes the --walk-reflogs flag' do
        expect_command_capturing('log', '--walk-reflogs').and_return(command_result)

        command.call(walk_reflogs: true)
      end

      it 'accepts :g as an alias for :walk_reflogs' do
        expect_command_capturing('log', '--walk-reflogs').and_return(command_result)

        command.call(g: true)
      end
    end

    context 'with the :merge option' do
      it 'includes the --merge flag' do
        expect_command_capturing('log', '--merge').and_return(command_result)

        command.call(merge: true)
      end
    end

    context 'with the :boundary option' do
      it 'includes the --boundary flag' do
        expect_command_capturing('log', '--boundary').and_return(command_result)

        command.call(boundary: true)
      end
    end

    # History Simplification

    context 'with the :simplify_by_decoration option' do
      it 'includes the --simplify-by-decoration flag' do
        expect_command_capturing('log', '--simplify-by-decoration').and_return(command_result)

        command.call(simplify_by_decoration: true)
      end
    end

    context 'with the :show_pulls option' do
      it 'includes the --show-pulls flag' do
        expect_command_capturing('log', '--show-pulls').and_return(command_result)

        command.call(show_pulls: true)
      end
    end

    context 'with the :full_history option' do
      it 'includes the --full-history flag' do
        expect_command_capturing('log', '--full-history').and_return(command_result)

        command.call(full_history: true)
      end
    end

    context 'with the :dense option' do
      it 'includes the --dense flag' do
        expect_command_capturing('log', '--dense').and_return(command_result)

        command.call(dense: true)
      end
    end

    context 'with the :sparse option' do
      it 'includes the --sparse flag' do
        expect_command_capturing('log', '--sparse').and_return(command_result)

        command.call(sparse: true)
      end
    end

    context 'with the :simplify_merges option' do
      it 'includes the --simplify-merges flag' do
        expect_command_capturing('log', '--simplify-merges').and_return(command_result)

        command.call(simplify_merges: true)
      end
    end

    context 'with the :ancestry_path option' do
      it 'includes the bare --ancestry-path flag when true' do
        expect_command_capturing('log', '--ancestry-path').and_return(command_result)

        command.call(ancestry_path: true)
      end

      it 'includes --ancestry-path=<commit> when a commit is given' do
        expect_command_capturing('log', '--ancestry-path=abc123').and_return(command_result)

        command.call(ancestry_path: 'abc123')
      end
    end

    # Commit Ordering

    context 'with the :date_order option' do
      it 'includes the --date-order flag' do
        expect_command_capturing('log', '--date-order').and_return(command_result)

        command.call(date_order: true)
      end
    end

    context 'with the :author_date_order option' do
      it 'includes the --author-date-order flag' do
        expect_command_capturing('log', '--author-date-order').and_return(command_result)

        command.call(author_date_order: true)
      end
    end

    context 'with the :topo_order option' do
      it 'includes the --topo-order flag' do
        expect_command_capturing('log', '--topo-order').and_return(command_result)

        command.call(topo_order: true)
      end
    end

    context 'with the :reverse option' do
      it 'includes the --reverse flag' do
        expect_command_capturing('log', '--reverse').and_return(command_result)

        command.call(reverse: true)
      end
    end

    # Object Traversal

    context 'with the :no_walk option' do
      it 'includes the bare --no-walk flag when true' do
        expect_command_capturing('log', '--no-walk').and_return(command_result)

        command.call(no_walk: true)
      end

      it 'includes --no-walk=unsorted when "unsorted"' do
        expect_command_capturing('log', '--no-walk=unsorted').and_return(command_result)

        command.call(no_walk: 'unsorted')
      end
    end

    context 'with the :do_walk option' do
      it 'includes the --do-walk flag' do
        expect_command_capturing('log', '--do-walk').and_return(command_result)

        command.call(do_walk: true)
      end
    end

    # Commit Formatting

    context 'with the :pretty / :format option' do
      it 'includes the bare --pretty flag when true' do
        expect_command_capturing('log', '--pretty').and_return(command_result)

        command.call(pretty: true)
      end

      it 'includes --pretty=raw when pretty: "raw"' do
        expect_command_capturing('log', '--pretty=raw').and_return(command_result)

        command.call(pretty: 'raw')
      end

      it 'accepts :format as an alias for :pretty' do
        expect_command_capturing('log', '--pretty=oneline').and_return(command_result)

        command.call(format: 'oneline')
      end
    end

    context 'with the :abbrev_commit option' do
      it 'includes the --abbrev-commit flag when true' do
        expect_command_capturing('log', '--abbrev-commit').and_return(command_result)

        command.call(abbrev_commit: true)
      end

      context 'when :no_abbrev_commit is true' do
        it 'includes the --no-abbrev-commit flag' do
          expect_command_capturing('log', '--no-abbrev-commit').and_return(command_result)

          command.call(no_abbrev_commit: true)
        end
      end
    end

    context 'with the :oneline option' do
      it 'includes the --oneline flag' do
        expect_command_capturing('log', '--oneline').and_return(command_result)

        command.call(oneline: true)
      end
    end

    context 'with the :encoding option' do
      it 'includes --encoding=<value>' do
        expect_command_capturing('log', '--encoding=UTF-8').and_return(command_result)

        command.call(encoding: 'UTF-8')
      end
    end

    context 'with the :expand_tabs option' do
      it 'includes the bare --expand-tabs flag when true' do
        expect_command_capturing('log', '--expand-tabs').and_return(command_result)

        command.call(expand_tabs: true)
      end

      it 'includes --expand-tabs=<n> when given a value' do
        expect_command_capturing('log', '--expand-tabs=4').and_return(command_result)

        command.call(expand_tabs: '4')
      end

      context 'when :no_expand_tabs is true' do
        it 'includes the --no-expand-tabs flag' do
          expect_command_capturing('log', '--no-expand-tabs').and_return(command_result)

          command.call(no_expand_tabs: true)
        end
      end
    end

    context 'with the :notes option' do
      it 'includes the bare --notes flag when true' do
        expect_command_capturing('log', '--notes').and_return(command_result)

        command.call(notes: true)
      end

      it 'includes --notes=<ref> when a ref is given' do
        expect_command_capturing('log', '--notes=refs/notes/review').and_return(command_result)

        command.call(notes: 'refs/notes/review')
      end

      context 'when :no_notes is true' do
        it 'includes the --no-notes flag' do
          expect_command_capturing('log', '--no-notes').and_return(command_result)

          command.call(no_notes: true)
        end
      end
    end

    context 'with the :show_notes_by_default option' do
      it 'includes the --show-notes-by-default flag' do
        expect_command_capturing('log', '--show-notes-by-default').and_return(command_result)

        command.call(show_notes_by_default: true)
      end
    end

    context 'with the :show_signature option' do
      it 'includes the --show-signature flag' do
        expect_command_capturing('log', '--show-signature').and_return(command_result)

        command.call(show_signature: true)
      end
    end

    context 'with the :relative_date option' do
      it 'includes the --relative-date flag' do
        expect_command_capturing('log', '--relative-date').and_return(command_result)

        command.call(relative_date: true)
      end
    end

    context 'with the :date option' do
      it 'includes --date=<value>' do
        expect_command_capturing('log', '--date=iso').and_return(command_result)

        command.call(date: 'iso')
      end
    end

    context 'with the :parents option' do
      it 'includes the --parents flag' do
        expect_command_capturing('log', '--parents').and_return(command_result)

        command.call(parents: true)
      end
    end

    context 'with the :children option' do
      it 'includes the --children flag' do
        expect_command_capturing('log', '--children').and_return(command_result)

        command.call(children: true)
      end
    end

    context 'with the :left_right option' do
      it 'includes the --left-right flag' do
        expect_command_capturing('log', '--left-right').and_return(command_result)

        command.call(left_right: true)
      end
    end

    context 'with the :graph option' do
      it 'includes the --graph flag' do
        expect_command_capturing('log', '--graph').and_return(command_result)

        command.call(graph: true)
      end
    end

    context 'with the :show_linear_break option' do
      it 'includes the bare --show-linear-break flag when true' do
        expect_command_capturing('log', '--show-linear-break').and_return(command_result)

        command.call(show_linear_break: true)
      end

      it 'includes --show-linear-break=<text> when a string is given' do
        expect_command_capturing('log', '--show-linear-break=---').and_return(command_result)

        command.call(show_linear_break: '---')
      end
    end

    context 'with the :follow option' do
      it 'includes the --follow flag' do
        expect_command_capturing('log', '--follow').and_return(command_result)

        command.call(follow: true)
      end
    end

    context 'with the :decorate option' do
      it 'includes the bare --decorate flag when true' do
        expect_command_capturing('log', '--decorate').and_return(command_result)

        command.call(decorate: true)
      end

      it 'includes --decorate=<format> when a format is given' do
        expect_command_capturing('log', '--decorate=full').and_return(command_result)

        command.call(decorate: 'full')
      end

      context 'when :no_decorate is true' do
        it 'includes the --no-decorate flag' do
          expect_command_capturing('log', '--no-decorate').and_return(command_result)

          command.call(no_decorate: true)
        end
      end
    end

    context 'with the :decorate_refs option' do
      it 'includes --decorate-refs=<value>' do
        expect_command_capturing('log', '--decorate-refs=refs/heads/*').and_return(command_result)

        command.call(decorate_refs: 'refs/heads/*')
      end
    end

    context 'with the :decorate_refs_exclude option' do
      it 'includes --decorate-refs-exclude=<value>' do
        expect_command_capturing('log', '--decorate-refs-exclude=refs/remotes/*').and_return(command_result)

        command.call(decorate_refs_exclude: 'refs/remotes/*')
      end
    end

    context 'with the :clear_decorations option' do
      it 'includes the --clear-decorations flag' do
        expect_command_capturing('log', '--clear-decorations').and_return(command_result)

        command.call(clear_decorations: true)
      end
    end

    context 'with the :source option' do
      it 'includes the --source flag' do
        expect_command_capturing('log', '--source').and_return(command_result)

        command.call(source: true)
      end
    end

    context 'with the :use_mailmap option' do
      it 'includes the --use-mailmap flag when true' do
        expect_command_capturing('log', '--use-mailmap').and_return(command_result)

        command.call(use_mailmap: true)
      end

      context 'when :no_use_mailmap is true' do
        it 'includes the --no-use-mailmap flag' do
          expect_command_capturing('log', '--no-use-mailmap').and_return(command_result)

          command.call(no_use_mailmap: true)
        end
      end
    end

    context 'with the :full_diff option' do
      it 'includes the --full-diff flag' do
        expect_command_capturing('log', '--full-diff').and_return(command_result)

        command.call(full_diff: true)
      end
    end

    context 'with the :log_size option' do
      it 'includes the --log-size flag' do
        expect_command_capturing('log', '--log-size').and_return(command_result)

        command.call(log_size: true)
      end
    end

    # Diff Formatting

    context 'with the :patch option' do
      it 'includes the --patch flag' do
        expect_command_capturing('log', '--patch').and_return(command_result)

        command.call(patch: true)
      end

      it 'accepts :p as an alias for :patch' do
        expect_command_capturing('log', '--patch').and_return(command_result)

        command.call(p: true)
      end
    end

    context 'with the :no_patch option' do
      it 'includes the --no-patch flag' do
        expect_command_capturing('log', '--no-patch').and_return(command_result)

        command.call(no_patch: true)
      end

      it 'accepts :s as an alias for :no_patch' do
        expect_command_capturing('log', '--no-patch').and_return(command_result)

        command.call(s: true)
      end
    end

    context 'with the :diff_merges option' do
      it 'includes --diff-merges=<value>' do
        expect_command_capturing('log', '--diff-merges=separate').and_return(command_result)

        command.call(diff_merges: 'separate')
      end
    end

    context 'with the :no_diff_merges option' do
      it 'includes the --no-diff-merges flag' do
        expect_command_capturing('log', '--no-diff-merges').and_return(command_result)

        command.call(no_diff_merges: true)
      end
    end

    context 'with the :combined_all_paths option' do
      it 'includes the --combined-all-paths flag' do
        expect_command_capturing('log', '--combined-all-paths').and_return(command_result)

        command.call(combined_all_paths: true)
      end
    end

    context 'with the :raw option' do
      it 'includes the --raw flag' do
        expect_command_capturing('log', '--raw').and_return(command_result)

        command.call(raw: true)
      end
    end

    context 'with the :stat option' do
      it 'includes the bare --stat flag when true' do
        expect_command_capturing('log', '--stat').and_return(command_result)

        command.call(stat: true)
      end

      it 'includes --stat=<width> when given a string' do
        expect_command_capturing('log', '--stat=80').and_return(command_result)

        command.call(stat: '80')
      end
    end

    context 'with the :compact_summary option' do
      it 'includes the --compact-summary flag' do
        expect_command_capturing('log', '--compact-summary').and_return(command_result)

        command.call(compact_summary: true)
      end
    end

    context 'with the :numstat option' do
      it 'includes the --numstat flag' do
        expect_command_capturing('log', '--numstat').and_return(command_result)

        command.call(numstat: true)
      end
    end

    context 'with the :shortstat option' do
      it 'includes the --shortstat flag' do
        expect_command_capturing('log', '--shortstat').and_return(command_result)

        command.call(shortstat: true)
      end
    end

    context 'with the :dirstat option' do
      it 'includes the bare --dirstat flag when true' do
        expect_command_capturing('log', '--dirstat').and_return(command_result)

        command.call(dirstat: true)
      end

      it 'includes --dirstat=<params> when given a string' do
        expect_command_capturing('log', '--dirstat=files,10').and_return(command_result)

        command.call(dirstat: 'files,10')
      end
    end

    context 'with the :summary option' do
      it 'includes the --summary flag' do
        expect_command_capturing('log', '--summary').and_return(command_result)

        command.call(summary: true)
      end
    end

    context 'with the :name_only option' do
      it 'includes the --name-only flag' do
        expect_command_capturing('log', '--name-only').and_return(command_result)

        command.call(name_only: true)
      end
    end

    context 'with the :name_status option' do
      it 'includes the --name-status flag' do
        expect_command_capturing('log', '--name-status').and_return(command_result)

        command.call(name_status: true)
      end
    end

    context 'with the :submodule option' do
      it 'includes the bare --submodule flag when true' do
        expect_command_capturing('log', '--submodule').and_return(command_result)

        command.call(submodule: true)
      end

      it 'includes --submodule=<format> when given a string' do
        expect_command_capturing('log', '--submodule=diff').and_return(command_result)

        command.call(submodule: 'diff')
      end
    end

    context 'with the :color option' do
      it 'includes the bare --color flag when true' do
        expect_command_capturing('log', '--color').and_return(command_result)

        command.call(color: true)
      end

      it 'includes --color=always when color: "always"' do
        expect_command_capturing('log', '--color=always').and_return(command_result)

        command.call(color: 'always')
      end

      context 'when :no_color is true' do
        it 'includes --no-color' do
          expect_command_capturing('log', '--no-color').and_return(command_result)

          command.call(no_color: true)
        end
      end
    end

    context 'with the :full_index option' do
      it 'includes the --full-index flag' do
        expect_command_capturing('log', '--full-index').and_return(command_result)

        command.call(full_index: true)
      end
    end

    context 'with the :binary option' do
      it 'includes the --binary flag' do
        expect_command_capturing('log', '--binary').and_return(command_result)

        command.call(binary: true)
      end
    end

    context 'with the :abbrev option' do
      it 'includes the bare --abbrev flag when true' do
        expect_command_capturing('log', '--abbrev').and_return(command_result)

        command.call(abbrev: true)
      end

      it 'includes --abbrev=<n> when given a string' do
        expect_command_capturing('log', '--abbrev=7').and_return(command_result)

        command.call(abbrev: '7')
      end
    end

    context 'with the :diff_filter option' do
      it 'includes --diff-filter=<value>' do
        expect_command_capturing('log', '--diff-filter=AD').and_return(command_result)

        command.call(diff_filter: 'AD')
      end
    end

    context 'with the :find_renames option' do
      it 'includes the bare --find-renames flag when true' do
        expect_command_capturing('log', '--find-renames').and_return(command_result)

        command.call(find_renames: true)
      end

      it 'includes --find-renames=<n> when given a threshold' do
        expect_command_capturing('log', '--find-renames=90').and_return(command_result)

        command.call(find_renames: '90')
      end
    end

    context 'with the :find_copies option' do
      it 'includes the bare --find-copies flag when true' do
        expect_command_capturing('log', '--find-copies').and_return(command_result)

        command.call(find_copies: true)
      end

      it 'includes --find-copies=<n> when given a threshold' do
        expect_command_capturing('log', '--find-copies=90').and_return(command_result)

        command.call(find_copies: '90')
      end
    end

    context 'with the :find_copies_harder option' do
      it 'includes the --find-copies-harder flag' do
        expect_command_capturing('log', '--find-copies-harder').and_return(command_result)

        command.call(find_copies_harder: true)
      end
    end

    context 'with the :relative option' do
      it 'includes the bare --relative flag when true' do
        expect_command_capturing('log', '--relative').and_return(command_result)

        command.call(relative: true)
      end

      it 'includes --relative=<path> when given a path' do
        expect_command_capturing('log', '--relative=subdir/').and_return(command_result)

        command.call(relative: 'subdir/')
      end

      context 'when :no_relative is true' do
        it 'includes the --no-relative flag' do
          expect_command_capturing('log', '--no-relative').and_return(command_result)

          command.call(no_relative: true)
        end
      end
    end

    context 'with the :text option' do
      it 'includes the --text flag' do
        expect_command_capturing('log', '--text').and_return(command_result)

        command.call(text: true)
      end
    end

    context 'with the :ignore_space_at_eol option' do
      it 'includes the --ignore-space-at-eol flag' do
        expect_command_capturing('log', '--ignore-space-at-eol').and_return(command_result)

        command.call(ignore_space_at_eol: true)
      end
    end

    context 'with the :ignore_space_change option' do
      it 'includes the --ignore-space-change flag' do
        expect_command_capturing('log', '--ignore-space-change').and_return(command_result)

        command.call(ignore_space_change: true)
      end

      it 'accepts :b as an alias for :ignore_space_change' do
        expect_command_capturing('log', '--ignore-space-change').and_return(command_result)

        command.call(b: true)
      end
    end

    context 'with the :ignore_all_space option' do
      it 'includes the --ignore-all-space flag' do
        expect_command_capturing('log', '--ignore-all-space').and_return(command_result)

        command.call(ignore_all_space: true)
      end

      it 'accepts :w as an alias for :ignore_all_space' do
        expect_command_capturing('log', '--ignore-all-space').and_return(command_result)

        command.call(w: true)
      end
    end

    context 'with the :ignore_blank_lines option' do
      it 'includes the --ignore-blank-lines flag' do
        expect_command_capturing('log', '--ignore-blank-lines').and_return(command_result)

        command.call(ignore_blank_lines: true)
      end
    end

    context 'with the :ignore_matching_lines option' do
      it 'includes --ignore-matching-lines=<value>' do
        expect_command_capturing('log', '--ignore-matching-lines=^#').and_return(command_result)

        command.call(ignore_matching_lines: '^#')
      end
    end

    context 'with the :ext_diff option' do
      it 'includes the --ext-diff flag when true' do
        expect_command_capturing('log', '--ext-diff').and_return(command_result)

        command.call(ext_diff: true)
      end

      context 'when :no_ext_diff is true' do
        it 'includes the --no-ext-diff flag' do
          expect_command_capturing('log', '--no-ext-diff').and_return(command_result)

          command.call(no_ext_diff: true)
        end
      end
    end

    context 'with the :textconv option' do
      it 'includes the --textconv flag when true' do
        expect_command_capturing('log', '--textconv').and_return(command_result)

        command.call(textconv: true)
      end

      context 'when :no_textconv is true' do
        it 'includes the --no-textconv flag' do
          expect_command_capturing('log', '--no-textconv').and_return(command_result)

          command.call(no_textconv: true)
        end
      end
    end

    context 'with the :no_prefix option' do
      it 'includes the --no-prefix flag' do
        expect_command_capturing('log', '--no-prefix').and_return(command_result)

        command.call(no_prefix: true)
      end
    end

    context 'with the :src_prefix option' do
      it 'includes --src-prefix=<value>' do
        expect_command_capturing('log', '--src-prefix=old/').and_return(command_result)

        command.call(src_prefix: 'old/')
      end
    end

    context 'with the :dst_prefix option' do
      it 'includes --dst-prefix=<value>' do
        expect_command_capturing('log', '--dst-prefix=new/').and_return(command_result)

        command.call(dst_prefix: 'new/')
      end
    end

    # Operands and paths

    context 'with a :revision_range operand' do
      it 'appends a single revision range directly' do
        expect_command_capturing('log', 'v1.0..v2.0').and_return(command_result)

        command.call('v1.0..v2.0')
      end

      it 'appends multiple revision specifiers as separate arguments' do
        expect_command_capturing('log', 'v1.0', 'v2.0', '^v0.9').and_return(command_result)

        command.call('v1.0', 'v2.0', '^v0.9')
      end
    end

    context 'with a :path option' do
      it 'appends -- and the path(s)' do
        expect_command_capturing('log', '--', 'lib/').and_return(command_result)

        command.call(path: ['lib/'])
      end

      it 'supports multiple paths' do
        expect_command_capturing('log', '--', 'lib/', 'spec/').and_return(command_result)

        command.call(path: %w[lib/ spec/])
      end
    end

    context 'with combined options' do
      it 'includes all specified options in DSL order' do
        expect_command_capturing(
          'log',
          '--max-count=20', '--since=2 weeks ago', '--all',
          'v1.0', '--', 'lib/'
        ).and_return(command_result)

        command.call('v1.0', all: true, max_count: 20, since: '2 weeks ago', path: ['lib/'])
      end
    end

    context 'with execution options' do
      it 'forwards the timeout option' do
        expect_command_capturing('log', timeout: 30).and_return(command_result)

        command.call(timeout: 30)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(bogus: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
