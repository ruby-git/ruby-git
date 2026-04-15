# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements `git apply` to apply a patch to files and/or to the index
    #
    # Reads the supplied diff output (a patch) and applies it to files.
    # Without options, the command applies the patch only to working tree files.
    # With `index: true`, the patch is also applied to the index.
    # With `cached: true`, the patch is only applied to the index.
    #
    # @example Typical usage
    #   apply = Git::Commands::Apply.new(execution_context)
    #   apply.call('fix.patch')
    #   apply.call('fix.patch', cached: true)
    #   apply.call('fix.patch', check: true)
    #   apply.call('fix.patch', reverse: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-apply/2.53.0
    #
    # @see https://git-scm.com/docs/git-apply git-apply
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Apply < Git::Commands::Base
      arguments do
        literal 'apply'

        # Informational flags (turn off actual apply)
        flag_option :stat                                    # --stat
        flag_option :numstat                                 # --numstat
        flag_option :summary                                 # --summary
        flag_option :check                                   # --check

        # Application mode
        flag_option :index                                   # --index
        flag_option %i[intent_to_add N]                      # --intent-to-add (alias: :N)
        flag_option :three_way, as: '--3way'                 # --3way

        # 3-way merge conflict resolution
        flag_option :ours                                    # --ours
        flag_option :theirs                                  # --theirs
        flag_option :union                                   # --union

        # Apply behavior
        flag_option :apply                                   # --apply
        flag_option :no_add                                  # --no-add
        value_option :build_fake_ancestor, inline: true      # --build-fake-ancestor=<file>
        flag_option %i[reverse R]                            # --reverse (alias: :R)
        flag_option %i[allow_binary_replacement binary]      # --allow-binary-replacement (alias: :binary)
        flag_option :reject                                  # --reject
        flag_option :z                                       # -z

        # Strip/context levels
        value_option :p, inline: true                        # -p<n>
        value_option :C, inline: true                        # -C<n>

        # Patch parsing
        flag_option :unidiff_zero                            # --unidiff-zero
        flag_option :inaccurate_eof                          # --inaccurate-eof
        flag_option :recount                                 # --recount

        # Application scope
        flag_option :cached # --cached

        # Whitespace handling
        flag_option :ignore_space_change                     # --ignore-space-change
        flag_option :ignore_whitespace                       # --ignore-whitespace
        value_option :whitespace, inline: true               # --whitespace=<action>

        # Path filtering
        value_option :exclude, inline: true                  # --exclude=<path-pattern>
        value_option :include, inline: true                  # --include=<path-pattern>
        value_option :directory, inline: true                # --directory=<root>

        # Verbosity
        flag_option %i[verbose v]                            # --verbose (alias: :v)
        flag_option %i[quiet q]                              # --quiet (alias: :q)
        flag_option :unsafe_paths                            # --unsafe-paths
        flag_option :allow_empty                             # --allow-empty

        # Execution
        execution_option :chdir

        end_of_options
        operand :patch, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*patch, **options)
      #
      #     Apply one or more patch files to the working tree or index
      #
      #     @param patch [Array<String>] zero or more patch file paths to apply;
      #       omit to read from standard input
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :stat (nil) show diffstat for the input
      #       instead of applying
      #
      #       Turns off apply mode.
      #
      #     @option options [Boolean] :numstat (nil) show numeric diffstat for
      #       the input instead of applying
      #
      #       Turns off apply mode. Output is in machine-friendly decimal format.
      #
      #     @option options [Boolean] :summary (nil) show a condensed summary of
      #       extended header information instead of applying
      #
      #       Turns off apply mode.
      #
      #     @option options [Boolean] :check (nil) check whether the patch applies
      #       cleanly without modifying any files
      #
      #       Turns off apply mode.
      #
      #     @option options [Boolean] :index (nil) apply the patch to both the
      #       index and the working tree
      #
      #     @option options [Boolean] :intent_to_add (nil) mark new files added by
      #       the patch for later addition to the index
      #
      #       Alias: `:N`
      #
      #     @option options [Boolean] :three_way (nil) attempt a 3-way merge if
      #       the patch does not apply cleanly (`--3way`)
      #
      #     @option options [Boolean] :ours (nil) resolve 3-way conflicts by
      #       favouring our side of the conflict
      #
      #       Requires `:three_way`.
      #
      #     @option options [Boolean] :theirs (nil) resolve 3-way conflicts by
      #       favouring their side of the conflict
      #
      #       Requires `:three_way`.
      #
      #     @option options [Boolean] :union (nil) resolve 3-way conflicts by
      #       including both sides of the conflict
      #
      #       Requires `:three_way`.
      #
      #     @option options [Boolean] :apply (nil) re-enable the apply step even
      #       when a "turns off apply" flag such as `:stat` is also given
      #
      #     @option options [Boolean] :no_add (nil) ignore additions made by the
      #       patch; apply only the deletions
      #
      #     @option options [String] :build_fake_ancestor (nil) path to a
      #       temporary index file for building a fake ancestor from the embedded
      #       blob identities in the patch
      #
      #     @option options [Boolean] :reverse (nil) apply the patch in reverse
      #
      #       Alias: `:R`
      #
      #     @option options [Boolean] :allow_binary_replacement (nil) allow
      #       binary patch application (no-op in Git 2.28+)
      #
      #       Alias: `:binary`
      #
      #     @option options [Boolean] :reject (nil) leave rejected hunks in
      #       `.rej` files instead of aborting
      #
      #     @option options [Boolean] :z (nil) use NUL-terminated output for
      #       `--numstat` pathnames (`-z`)
      #
      #     @option options [Integer] :p (nil) strip this many leading path
      #       components from traditional diff paths (`-p<n>`)
      #
      #     @option options [Integer] :C (nil) require at least this many lines
      #       of surrounding context before and after each change (`-C<n>`)
      #
      #     @option options [Boolean] :unidiff_zero (nil) bypass context-line
      #       safety checks for diffs generated with `--unified=0`
      #
      #     @option options [Boolean] :inaccurate_eof (nil) work around diffs
      #       that do not correctly detect a missing newline at end of file
      #
      #     @option options [Boolean] :recount (nil) infer hunk sizes from the
      #       patch content rather than trusting the hunk header counts
      #
      #     @option options [Boolean] :cached (nil) apply the patch only to the
      #       index without touching the working tree
      #
      #     @option options [Boolean] :ignore_space_change (nil) ignore changes
      #       in the amount of whitespace in context lines
      #
      #     @option options [Boolean] :ignore_whitespace (nil) ignore all
      #       whitespace differences in context lines
      #
      #     @option options [String] :whitespace (nil) whitespace error handling
      #       mode: `'nowarn'`, `'warn'`, `'fix'`, `'error'`, or `'error-all'`
      #
      #     @option options [String] :exclude (nil) skip changes to files
      #       matching this path pattern
      #
      #     @option options [String] :include (nil) apply changes only to files
      #       matching this path pattern
      #
      #     @option options [String] :directory (nil) prepend this root to all
      #       filenames in the patch
      #
      #     @option options [Boolean] :verbose (nil) report progress to stderr
      #
      #       Alias: `:v`
      #
      #     @option options [Boolean] :quiet (nil) suppress stderr output
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean] :unsafe_paths (nil) override the safety
      #       check that rejects patches affecting paths outside the working area
      #
      #     @option options [Boolean] :allow_empty (nil) do not return an error
      #       for patches containing no diff
      #
      #     @option options [String] :chdir (nil) change to this directory before
      #       running git; not passed to the git CLI
      #
      #     @return [Git::CommandLineResult] the result of calling `git apply`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #     @api public
    end
  end
end
