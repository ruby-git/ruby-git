# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Checkout
      # Implements the `git checkout` command for restoring working tree files
      #
      # This command replaces files in the working tree with versions from
      # the index (when tree_ish is nil) or a specified tree-ish (commit,
      # branch, tag, etc.).
      #
      # @example Restore working tree files
      #   files = Git::Commands::Checkout::Files.new(execution_context)
      #   files.call(pathspec: ['lib/foo.rb'])                             # from the index
      #   files.call('HEAD~1', pathspec: ['lib/foo.rb'])                   # from a specific commit
      #   files.call('main', pathspec: %w[lib/foo.rb lib/bar.rb])          # from a branch
      #   files.call(pathspec: ['conflicted.txt'], ours: true)             # resolve conflict (ours)
      #   files.call('main', pathspec_from_file: 'paths.txt')              # paths from a file
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-checkout/2.53.0
      #
      # @see Git::Commands::Checkout
      #
      # @see https://git-scm.com/docs/git-checkout git-checkout
      #
      # @api private
      #
      class Files < Git::Commands::Base
        arguments do
          literal 'checkout'
          flag_option %i[force f]                                     # --force (alias: :f)
          flag_option :ours                                           # --ours
          flag_option :theirs                                         # --theirs
          flag_option %i[merge m]                                     # --merge (alias: :m)
          value_option :conflict, inline: true                        # --conflict=<style>
          flag_option :overlay, negatable: true                       # --overlay / --no-overlay
          flag_option :ignore_skip_worktree_bits                      # --ignore-skip-worktree-bits
          value_option :pathspec_from_file, inline: true              # --pathspec-from-file=<file>
          flag_option :pathspec_file_nul                              # --pathspec-file-nul

          execution_option :chdir

          operand :tree_ish
          end_of_options
          value_option :pathspec, as_operand: true, repeatable: true  # <pathspec>...
        end

        # @!method call(*, **)
        #
        #   @overload call(tree_ish = nil, **options)
        #
        #     Execute the git checkout command for restoring files
        #
        #     @param tree_ish [String, nil] The commit, branch, or tree to restore
        #       files from
        #
        #       When `nil`, files are restored from the index
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (false) ignore unmerged entries
        #
        #       Alias: `:f`
        #
        #     @option options [Boolean] :ours (false) for unmerged paths, check out
        #       stage #2 (our version)
        #
        #     @option options [Boolean] :theirs (false) for unmerged paths, check out
        #       stage #3 (their version)
        #
        #     @option options [Boolean] :merge (false) recreate the conflicted merge in
        #       the specified paths; cannot be used when checking out from a tree-ish
        #
        #       Alias: `:m`
        #
        #     @option options [String] :conflict (nil) conflict marker style; valid
        #       values are `'merge'`, `'diff3'`, and `'zdiff3'`
        #
        #     @option options [Boolean] :overlay (nil) use `true` for `--overlay`
        #       (never removes files from the index or working tree); use `false` for
        #       `--no-overlay` (removes files not present in the tree-ish)
        #
        #     @option options [Boolean] :ignore_skip_worktree_bits (false) in sparse
        #       checkout mode, ignore sparse patterns and update all files matched by
        #       pathspec
        #
        #     @option options [String] :pathspec_from_file (nil) read pathspec from
        #       this file; pass `'-'` to read from stdin
        #
        #     @option options [Boolean] :pathspec_file_nul (false) with
        #       `:pathspec_from_file`, separate pathspec elements with NUL instead of
        #       newline
        #
        #     @option options [Array<String>, String] :pathspec (nil) the files or
        #       directories to restore
        #
        #     @option options [String] :chdir (nil) change to this directory before
        #       running git; not passed to the git CLI
        #
        #     @return [Git::CommandLineResult] the result of calling `git checkout`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @api public
        #
      end
    end
  end
end
