# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Remove untracked files from the working tree
    #
    # Cleans the working tree by recursively removing files that are not under
    # version control. Only files unknown to Git are removed by default; with
    # `:x` also removes ignored files; with `:X` removes only ignored files.
    #
    # @example Typical usage
    #   clean = Git::Commands::Clean.new(execution_context)
    #   clean.call(force: true)
    #   clean.call(force: true, d: true)
    #   clean.call(force: 2)
    #   clean.call(dry_run: true)
    #   clean.call(force: true, exclude: '*.log')
    #   clean.call(force: true, X: true)
    #   clean.call(force: true, pathspec: ['tmp/', 'build/'])
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-clean/2.53.0
    #
    # @see Git::Commands
    #
    # @see https://git-scm.com/docs/git-clean git-clean
    #
    # @api private
    #
    class Clean < Git::Commands::Base
      arguments do
        literal 'clean'
        flag_option :d # -d
        flag_option %i[force f], max_times: 2 # --force (alias: :f)
        flag_option %i[dry_run n] # --dry-run (alias: :n)
        flag_option %i[quiet q] # --quiet (alias: :q)
        value_option %i[exclude e], inline: true, repeatable: true # --exclude=<pattern> (alias: :e)
        flag_option :x  # -x
        flag_option :X  # -X
        execution_option :chdir
        end_of_options
        value_option :pathspec, as_operand: true, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Execute the git clean command
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :d (false) recurse into untracked directories
      #
      #     @option options [Boolean, Integer] :force (false) force the removal of untracked files
      #
      #       When `clean.requireForce` is not set to `false`, git-clean will refuse to
      #       delete files or directories unless this option is given.
      #
      #       Pass `true` or `1` to emit `--force` once. Pass `2` to emit `--force --force`,
      #       which also removes untracked nested git repositories (directories with a
      #       `.git` subdirectory).
      #
      #       Alias: `:f`
      #
      #     @option options [Boolean] :dry_run (false) don't actually remove anything, just
      #       show what would be done
      #
      #       Alias: `:n`
      #
      #     @option options [Boolean] :quiet (false) be quiet, only report errors
      #
      #       Alias: `:q`
      #
      #     @option options [String, Array<String>] :exclude (nil) use the given exclude
      #       pattern in addition to the standard ignore rules
      #
      #       May be specified multiple times. Alias: `:e`
      #
      #     @option options [Boolean] :x (false) don't use the standard ignore rules
      #
      #     @option options [Boolean] :X (false) remove only files ignored by Git
      #
      #     @option options [String, Array<String>] :pathspec (nil) limit cleaning to files
      #       matching the given pathspec(s)
      #
      #     @option options [String, nil] :chdir (nil) change to this directory before
      #       running git; not passed to the git CLI
      #
      #     @return [Git::CommandLineResult] the result of calling `git clean`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
    end
  end
end
