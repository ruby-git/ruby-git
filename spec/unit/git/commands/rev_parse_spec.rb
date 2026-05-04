# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/rev_parse'

RSpec.describe Git::Commands::RevParse do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a revision argument' do
      it 'runs rev-parse with the revision' do
        expected_result = command_result("abc123\n")
        expect_command_capturing('rev-parse', '--end-of-options', 'HEAD').and_return(expected_result)

        result = command.call('HEAD')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple arguments' do
      it 'passes all arguments as operands' do
        expect_command_capturing('rev-parse', '--end-of-options', 'HEAD', 'v1.0')
          .and_return(command_result("abc\ndef\n"))

        command.call('HEAD', 'v1.0')
      end
    end

    # Filtering options

    context 'with the :revs_only option' do
      it 'adds --revs-only to the command line' do
        expect_command_capturing('rev-parse', '--revs-only', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', revs_only: true)
      end
    end

    context 'with the :no_revs option' do
      it 'adds --no-revs to the command line' do
        expect_command_capturing('rev-parse', '--no-revs', '--end-of-options', 'HEAD')
          .and_return(command_result)

        command.call('HEAD', no_revs: true)
      end
    end

    context 'with the :flags option' do
      it 'adds --flags to the command line' do
        expect_command_capturing('rev-parse', '--flags', '--end-of-options', 'HEAD')
          .and_return(command_result)

        command.call('HEAD', flags: true)
      end

      context 'when :no_flags is true' do
        it 'adds --no-flags to the command line' do
          expect_command_capturing('rev-parse', '--no-flags', '--end-of-options', 'HEAD')
            .and_return(command_result("HEAD\n"))

          command.call('HEAD', no_flags: true)
        end
      end
    end

    # Output options

    context 'with the :default option' do
      it 'adds --default with the given value' do
        expect_command_capturing('rev-parse', '--default', 'master').and_return(command_result("abc123\n"))

        command.call(default: 'master')
      end
    end

    context 'with the :prefix option' do
      it 'adds --prefix with the given value' do
        expect_command_capturing('rev-parse', '--prefix', 'src/').and_return(command_result)

        command.call(prefix: 'src/')
      end
    end

    context 'with the :verify option' do
      it 'adds --verify to the command line' do
        expect_command_capturing('rev-parse', '--verify', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', verify: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('rev-parse', '--quiet', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', quiet: true)
      end
    end

    context 'with the :q alias' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('rev-parse', '--quiet', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', q: true)
      end
    end

    context 'with the :sq option' do
      it 'adds --sq to the command line' do
        expect_command_capturing('rev-parse', '--sq', '--end-of-options', 'HEAD')
          .and_return(command_result("'abc123'\n"))

        command.call('HEAD', sq: true)
      end
    end

    context 'with the :short option' do
      it 'adds --short when true' do
        expect_command_capturing('rev-parse', '--short', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', short: true)
      end

      it 'adds --short=<length> when given a string' do
        expect_command_capturing('rev-parse', '--short=8', '--end-of-options', 'HEAD')
          .and_return(command_result("abc12345\n"))

        command.call('HEAD', short: '8')
      end
    end

    context 'with the :not option' do
      it 'adds --not to the command line' do
        expect_command_capturing('rev-parse', '--not', '--end-of-options', 'HEAD')
          .and_return(command_result("^abc123\n"))

        command.call('HEAD', not: true)
      end
    end

    context 'with the :abbrev_ref option' do
      it 'adds --abbrev-ref when true' do
        expect_command_capturing('rev-parse', '--abbrev-ref', '--end-of-options', 'HEAD')
          .and_return(command_result("main\n"))

        command.call('HEAD', abbrev_ref: true)
      end

      it 'adds --abbrev-ref=<mode> when given a string' do
        expect_command_capturing('rev-parse', '--abbrev-ref=strict', '--end-of-options', 'HEAD')
          .and_return(command_result("main\n"))

        command.call('HEAD', abbrev_ref: 'strict')
      end
    end

    context 'with the :symbolic option' do
      it 'adds --symbolic to the command line' do
        expect_command_capturing('rev-parse', '--symbolic', '--end-of-options', 'HEAD')
          .and_return(command_result("HEAD\n"))

        command.call('HEAD', symbolic: true)
      end
    end

    context 'with the :symbolic_full_name option' do
      it 'adds --symbolic-full-name to the command line' do
        expect_command_capturing('rev-parse', '--symbolic-full-name', '--end-of-options', 'HEAD')
          .and_return(command_result("refs/heads/main\n"))

        command.call('HEAD', symbolic_full_name: true)
      end
    end

    context 'with the :output_object_format option' do
      it 'adds --output-object-format=<format> to the command line' do
        expect_command_capturing('rev-parse', '--output-object-format=sha1', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', output_object_format: 'sha1')
      end
    end

    # Object options

    context 'with the :all option' do
      it 'adds --all to the command line' do
        expect_command_capturing('rev-parse', '--all').and_return(command_result("abc123\n"))

        command.call(all: true)
      end
    end

    context 'with the :branches option' do
      it 'adds --branches when true' do
        expect_command_capturing('rev-parse', '--branches').and_return(command_result("abc123\n"))

        command.call(branches: true)
      end

      it 'adds --branches=<pattern> when given a string' do
        expect_command_capturing('rev-parse', '--branches=feature/*').and_return(command_result("abc123\n"))

        command.call(branches: 'feature/*')
      end
    end

    context 'with the :tags option' do
      it 'adds --tags when true' do
        expect_command_capturing('rev-parse', '--tags').and_return(command_result("abc123\n"))

        command.call(tags: true)
      end

      it 'adds --tags=<pattern> when given a string' do
        expect_command_capturing('rev-parse', '--tags=v*').and_return(command_result("abc123\n"))

        command.call(tags: 'v*')
      end
    end

    context 'with the :remotes option' do
      it 'adds --remotes when true' do
        expect_command_capturing('rev-parse', '--remotes').and_return(command_result("abc123\n"))

        command.call(remotes: true)
      end

      it 'adds --remotes=<pattern> when given a string' do
        expect_command_capturing('rev-parse', '--remotes=origin/*').and_return(command_result("abc123\n"))

        command.call(remotes: 'origin/*')
      end
    end

    context 'with the :glob option' do
      it 'adds --glob=<pattern> to the command line' do
        expect_command_capturing('rev-parse', '--glob=refs/heads/*').and_return(command_result("abc123\n"))

        command.call(glob: 'refs/heads/*')
      end
    end

    context 'with the :exclude option' do
      it 'adds --exclude=<pattern> to the command line' do
        expect_command_capturing('rev-parse', '--exclude=refs/stash').and_return(command_result)

        command.call(exclude: 'refs/stash')
      end

      it 'supports repeatable exclude patterns' do
        expect_command_capturing('rev-parse', '--exclude=refs/stash', '--exclude=refs/notes/*')
          .and_return(command_result)

        command.call(exclude: ['refs/stash', 'refs/notes/*'])
      end
    end

    context 'with the :exclude_hidden option' do
      it 'adds --exclude-hidden=<protocol> to the command line' do
        expect_command_capturing('rev-parse', '--exclude-hidden=fetch').and_return(command_result)

        command.call(exclude_hidden: 'fetch')
      end
    end

    context 'with the :disambiguate option' do
      it 'adds --disambiguate=<prefix> to the command line' do
        expect_command_capturing('rev-parse', '--disambiguate=abc1').and_return(command_result("abc123\nabc1ff\n"))

        command.call(disambiguate: 'abc1')
      end
    end

    # Files options

    context 'with the :local_env_vars option' do
      it 'adds --local-env-vars to the command line' do
        expect_command_capturing('rev-parse', '--local-env-vars').and_return(command_result("GIT_DIR\n"))

        command.call(local_env_vars: true)
      end
    end

    context 'with the :path_format option' do
      it 'adds --path-format=<format> to the command line' do
        expect_command_capturing('rev-parse', '--path-format=absolute').and_return(command_result)

        command.call(path_format: 'absolute')
      end

      it 'supports repeatable path-format values' do
        expect_command_capturing('rev-parse', '--path-format=absolute', '--path-format=relative')
          .and_return(command_result)

        command.call(path_format: %w[absolute relative])
      end
    end

    context 'with the :git_dir option' do
      it 'adds --git-dir to the command line' do
        expect_command_capturing('rev-parse', '--git-dir').and_return(command_result(".git\n"))

        command.call(git_dir: true)
      end
    end

    context 'with the :absolute_git_dir option' do
      it 'adds --absolute-git-dir to the command line' do
        expect_command_capturing('rev-parse', '--absolute-git-dir').and_return(command_result("/path/.git\n"))

        command.call(absolute_git_dir: true)
      end
    end

    context 'with the :git_common_dir option' do
      it 'adds --git-common-dir to the command line' do
        expect_command_capturing('rev-parse', '--git-common-dir').and_return(command_result(".git\n"))

        command.call(git_common_dir: true)
      end
    end

    context 'with the :is_inside_git_dir option' do
      it 'adds --is-inside-git-dir to the command line' do
        expect_command_capturing('rev-parse', '--is-inside-git-dir').and_return(command_result("false\n"))

        command.call(is_inside_git_dir: true)
      end
    end

    context 'with the :is_inside_work_tree option' do
      it 'adds --is-inside-work-tree to the command line' do
        expect_command_capturing('rev-parse', '--is-inside-work-tree').and_return(command_result("true\n"))

        command.call(is_inside_work_tree: true)
      end
    end

    context 'with the :is_bare_repository option' do
      it 'adds --is-bare-repository to the command line' do
        expect_command_capturing('rev-parse', '--is-bare-repository').and_return(command_result("false\n"))

        command.call(is_bare_repository: true)
      end
    end

    context 'with the :is_shallow_repository option' do
      it 'adds --is-shallow-repository to the command line' do
        expect_command_capturing('rev-parse', '--is-shallow-repository').and_return(command_result("false\n"))

        command.call(is_shallow_repository: true)
      end
    end

    context 'with the :resolve_git_dir option' do
      it 'adds --resolve-git-dir with the given path' do
        expect_command_capturing('rev-parse', '--resolve-git-dir', '.git').and_return(command_result("/path/.git\n"))

        command.call(resolve_git_dir: '.git')
      end
    end

    context 'with the :git_path option' do
      it 'adds --git-path with the given path' do
        expect_command_capturing('rev-parse', '--git-path',
                                 'objects').and_return(command_result("/path/.git/objects\n"))

        command.call(git_path: 'objects')
      end
    end

    context 'with the :show_cdup option' do
      it 'adds --show-cdup to the command line' do
        expect_command_capturing('rev-parse', '--show-cdup').and_return(command_result("../../\n"))

        command.call(show_cdup: true)
      end
    end

    context 'with the :show_prefix option' do
      it 'adds --show-prefix to the command line' do
        expect_command_capturing('rev-parse', '--show-prefix').and_return(command_result("src/\n"))

        command.call(show_prefix: true)
      end
    end

    context 'with the :show_toplevel option' do
      it 'adds --show-toplevel to the command line' do
        expect_command_capturing('rev-parse', '--show-toplevel').and_return(command_result("/path/to/repo\n"))

        command.call(show_toplevel: true)
      end
    end

    context 'with the :show_superproject_working_tree option' do
      it 'adds --show-superproject-working-tree to the command line' do
        expect_command_capturing('rev-parse', '--show-superproject-working-tree').and_return(command_result)

        command.call(show_superproject_working_tree: true)
      end
    end

    context 'with the :shared_index_path option' do
      it 'adds --shared-index-path to the command line' do
        expect_command_capturing('rev-parse', '--shared-index-path').and_return(command_result)

        command.call(shared_index_path: true)
      end
    end

    context 'with the :show_object_format option' do
      it 'adds --show-object-format when true' do
        expect_command_capturing('rev-parse', '--show-object-format').and_return(command_result("sha1\n"))

        command.call(show_object_format: true)
      end

      it 'adds --show-object-format=<mode> when given a string' do
        expect_command_capturing('rev-parse', '--show-object-format=input').and_return(command_result("sha1\n"))

        command.call(show_object_format: 'input')
      end
    end

    context 'with the :show_ref_format option' do
      it 'adds --show-ref-format to the command line' do
        expect_command_capturing('rev-parse', '--show-ref-format').and_return(command_result("files\n"))

        command.call(show_ref_format: true)
      end
    end

    # Date conversion options

    context 'with the :since option' do
      it 'adds --since=<date> to the command line' do
        expect_command_capturing('rev-parse', '--since=2024-01-01').and_return(command_result("--max-age=1704067200\n"))

        command.call(since: '2024-01-01')
      end
    end

    context 'with the :after alias' do
      it 'adds --since=<date> to the command line' do
        expect_command_capturing('rev-parse', '--since=2024-01-01').and_return(command_result("--max-age=1704067200\n"))

        command.call(after: '2024-01-01')
      end
    end

    context 'with the :until option' do
      it 'adds --until=<date> to the command line' do
        expect_command_capturing('rev-parse', '--until=2024-12-31').and_return(command_result("--min-age=1735603200\n"))

        command.call(until: '2024-12-31')
      end
    end

    context 'with the :before alias' do
      it 'adds --until=<date> to the command line' do
        expect_command_capturing('rev-parse', '--until=2024-12-31').and_return(command_result("--min-age=1735603200\n"))

        command.call(before: '2024-12-31')
      end
    end

    # Combined options

    context 'with :verify and :quiet combined' do
      it 'includes both flags' do
        expect_command_capturing('rev-parse', '--verify', '--quiet', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', verify: true, quiet: true)
      end
    end

    # Execution options

    context 'with the :chdir execution option' do
      it 'passes chdir to the execution context, not to the git CLI' do
        expect_command_capturing('rev-parse', '--end-of-options', 'HEAD', chdir: '/some/dir')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', chdir: '/some/dir')
      end
    end

    # end_of_options placement

    context 'end_of_options as: "--end-of-options"' do
      it 'emits --end-of-options before operands' do
        expect_command_capturing('rev-parse', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD')
      end

      it 'omits --end-of-options when no operands are given' do
        expect_command_capturing('rev-parse', '--show-toplevel')
          .and_return(command_result("/path/to/repo\n"))

        command.call(show_toplevel: true)
      end

      it 'allows "--" as an operand value to separate verified from passthrough args' do
        expect_command_capturing('rev-parse', '--end-of-options', 'HEAD', '--', 'file.txt')
          .and_return(command_result("abc123\nfile.txt\n"))

        command.call('HEAD', '--', 'file.txt')
      end

      it 'allows hyphen-prefixed operand values' do
        expect_command_capturing('rev-parse', '--end-of-options', '-tricky-branch')
          .and_return(command_result("abc123\n"))

        command.call('-tricky-branch')
      end

      it 'places --end-of-options after all options and before all operands' do
        expect_command_capturing('rev-parse', '--verify', '--quiet', '--end-of-options', 'HEAD')
          .and_return(command_result("abc123\n"))

        command.call('HEAD', verify: true, quiet: true)
      end
    end

    # Input validation

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
