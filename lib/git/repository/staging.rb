# frozen_string_literal: true

require 'git/commands/add'
require 'git/commands/am/apply'
require 'git/commands/apply'
require 'git/commands/clean'
require 'git/commands/ls_files'
require 'git/commands/mv'
require 'git/commands/read_tree'
require 'git/commands/reset'
require 'git/commands/rm'
require 'git/escaped_path'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for staging-area operations: adding, resetting, moving,
    # removing, and cleaning files
    #
    # Included by {Git::Repository}.
    #
    # @api private
    #
    module Staging
      # Option keys accepted by {#add}
      ADD_ALLOWED_OPTS = %i[all force].freeze
      private_constant :ADD_ALLOWED_OPTS

      # Update the index with the current content found in the working tree
      #
      # @overload add(paths = '.', **options)
      #
      #   @example Stage all changed files
      #     repo.add
      #
      #   @example Stage a specific file
      #     repo.add('README.md')
      #
      #   @example Stage all changes including deletions
      #     repo.add(all: true)
      #
      #   @param paths [String, Array<String>] a file or files to add (relative to
      #     the worktree root); defaults to `'.'` (all files)
      #
      #   @param options [Hash] options for the add command
      #
      #   @option options [Boolean, nil] :all (nil) add, modify, and remove index
      #     entries to match the worktree
      #
      #   @option options [Boolean, nil] :force (nil) allow adding otherwise ignored
      #     files
      #
      #   @return [String] git's stdout from the add
      #
      #   @raise [ArgumentError] when unsupported options are provided
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def add(paths = '.', **)
        SharedPrivate.assert_valid_opts!(ADD_ALLOWED_OPTS, **)
        Git::Commands::Add.new(@execution_context).call(*Array(paths), **).stdout
      end

      # Option keys accepted by {#reset}
      RESET_ALLOWED_OPTS = %i[hard].freeze
      private_constant :RESET_ALLOWED_OPTS

      # Reset the current HEAD to a specified state
      #
      # @example Reset the index and working tree to HEAD
      #   repo.reset
      #
      # @example Hard reset to a specific commit
      #   repo.reset('HEAD~1', hard: true)
      #
      # @param commitish [String, nil] the commit or tree-ish to reset to;
      #   defaults to HEAD when `nil`
      #
      # @param opts [Hash] options for the reset command
      #
      # @option opts [Boolean, nil] :hard (nil) reset the index and working
      #   tree; discards all tracked changes
      #
      # @return [String] git's stdout from the reset
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def reset(commitish = nil, opts = {})
        SharedPrivate.assert_valid_opts!(RESET_ALLOWED_OPTS, **opts)
        Git::Commands::Reset.new(@execution_context).call(commitish, **opts).stdout
      end

      # Reset the current HEAD to a specified state with `--hard`
      #
      # @example Hard reset to HEAD
      #   repo.reset_hard
      #
      # @example Hard reset to a specific commit
      #   repo.reset_hard('HEAD~1')
      #
      # @param commitish [String, nil] the commit or tree-ish to reset to;
      #   defaults to HEAD when `nil`
      #
      # @param opts [Hash] options passed through to {#reset}
      #
      # @option opts [Boolean, nil] :hard (nil) ignored; this method always forces
      #   `hard: true`
      #
      # @return [String] git's stdout from the reset
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      # @deprecated Use {#reset} with `hard: true` instead
      #
      def reset_hard(commitish = nil, opts = {})
        Git::Deprecation.warn(
          'Git::Repository#reset_hard is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#reset(commitish, hard: true) instead.'
        )
        reset(commitish, **opts, hard: true)
      end

      # Apply a patch file to the working tree
      #
      # Reads the unified diff in `file` and applies it to the working tree via
      # `git apply`. If `file` does not exist, the method returns `nil` without
      # calling git — preserving the 4.x `Git::Base#apply` no-op contract.
      #
      # @example Apply a patch to the working tree
      #   repo.apply('fix.patch')
      #
      # @param file [String] path to the patch file to apply
      #
      # @return [String] git's stdout (usually empty on success)
      #
      # @return [nil] when `file` does not exist
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def apply(file)
        return unless File.exist?(file)

        Git::Commands::Apply.new(@execution_context).call(file, chdir: @execution_context.git_work_dir).stdout
      end

      # Apply a series of patches from a mailbox file to the current branch
      #
      # Reads the mbox-format file in `file` and applies the patches via
      # `git am`. If `file` does not exist, the method returns `nil` without
      # calling git — preserving the 4.x `Git::Base#apply_mail` no-op contract.
      #
      # @example Apply patches from a mailbox
      #   repo.apply_mail('patches.mbox')
      #
      # @param file [String] path to the mbox patch file to apply
      #
      # @return [String] git's stdout (usually empty on success)
      #
      # @return [nil] when `file` does not exist
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def apply_mail(file)
        return unless File.exist?(file)

        Git::Commands::Am::Apply.new(@execution_context).call(file, chdir: @execution_context.git_work_dir).stdout
      end

      # Option keys accepted by {#read_tree}
      READ_TREE_ALLOWED_OPTS = %i[prefix].freeze
      private_constant :READ_TREE_ALLOWED_OPTS

      # Read tree information into the index
      #
      # Reads the named tree object into the index. This is a low-level plumbing
      # operation used to stage the contents of a tree without updating the
      # working tree. Typically called before {#checkout_index} or as part of
      # custom merge flows.
      #
      # @example Read HEAD into the index
      #   repo.read_tree('HEAD')
      #
      # @example Read a tree under a prefix directory
      #   repo.read_tree('HEAD', { prefix: 'subdir/' })
      #
      # @param treeish [String] the tree-ish to read into the index
      #
      # @param opts [Hash] options for the read-tree command
      #
      # @option opts [String] :prefix (nil) keep the current index contents and
      #   read the named tree-ish under the directory at the given prefix
      #   (`--prefix=<prefix>`)
      #
      # @return [String] git's stdout (usually empty on success)
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def read_tree(treeish, opts = {})
        SharedPrivate.assert_valid_opts!(READ_TREE_ALLOWED_OPTS, **opts)
        Git::Commands::ReadTree.new(@execution_context).call(treeish, **opts).stdout
      end

      # Option keys accepted by {#rm}
      RM_ALLOWED_OPTS = %i[
        force f dry_run n r cached ignore_unmatch sparse quiet q
        pathspec_from_file pathspec_file_nul
      ].freeze
      private_constant :RM_ALLOWED_OPTS

      # Remove file(s) from the working tree and the index
      #
      # @example Remove a single file
      #   repo.rm('obsolete.txt', { force: true })
      #
      # @example Remove a directory recursively
      #   repo.rm('build', { r: true })
      #
      # @example Remove from the index only, keeping the working tree copy
      #   repo.rm('keep_me.txt', { cached: true })
      #
      # @param path [String, Array<String>] a file or files to remove (relative to
      #   the worktree root); defaults to `'.'` (all files)
      #
      # @param opts [Hash] options for the rm command
      #
      # @option opts [Boolean, nil] :force (nil) override the up-to-date check and
      #   remove files with local modifications (alias: `:f`)
      #
      # @option opts [Boolean, nil] :f (nil) alias for `:force`
      #
      # @option opts [Boolean, nil] :dry_run (nil) do not actually remove any files;
      #   only show what would be removed (alias: `:n`)
      #
      # @option opts [Boolean, nil] :n (nil) alias for `:dry_run`
      #
      # @option opts [Boolean, nil] :r (nil) allow recursive removal when a leading
      #   directory name is given
      #
      # @option opts [Boolean, nil] :cached (nil) only remove from the index, keeping
      #   the working tree files
      #
      # @option opts [Boolean, nil] :ignore_unmatch (nil) exit with a zero status even
      #   if no files matched
      #
      # @option opts [Boolean, nil] :sparse (nil) allow updating index entries outside
      #   of the sparse-checkout cone
      #
      # @option opts [Boolean, nil] :quiet (nil) suppress the one-line-per-file output
      #   (alias: `:q`)
      #
      # @option opts [Boolean, nil] :q (nil) alias for `:quiet`
      #
      # @option opts [String] :pathspec_from_file (nil) read pathspec from the given
      #   file, one pathspec element per line; pass `-` to read from standard input
      #
      # @option opts [Boolean, nil] :pathspec_file_nul (nil) when used with
      #   `:pathspec_from_file`, separate pathspec elements with NUL instead of newlines
      #
      # @return [String] git's stdout from the rm
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def rm(path = '.', opts = {})
        SharedPrivate.assert_valid_opts!(RM_ALLOWED_OPTS, **opts)
        Git::Commands::Rm.new(@execution_context).call(*Array(path), **opts).stdout
      end

      alias remove rm

      # Option keys accepted by {#mv}
      MV_ALLOWED_OPTS = %i[force f dry_run n k].freeze
      private_constant :MV_ALLOWED_OPTS

      # Move or rename a file, directory, or symlink in the working tree
      #
      # Updates the index after successful completion, but the change must still
      # be committed.
      #
      # @example Move a single file
      #   repo.mv('old.rb', 'new.rb')
      #
      # @example Move multiple files to a directory
      #   repo.mv(['file1.rb', 'file2.rb'], 'destination_dir/')
      #
      # @example Force overwrite if destination exists
      #   repo.mv('source.rb', 'dest.rb', force: true)
      #
      # @param source [String, Array<String>] one or more source file(s),
      #   directory(ies), or symlink(s) to move (relative to the worktree root)
      #
      # @param destination [String] the destination file or directory
      #
      # @param options [Hash] options for the mv command
      #
      # @option options [Boolean, nil] :force (nil) force renaming or moving even
      #   if the destination exists (alias: `:f`)
      #
      # @option options [Boolean, nil] :f (nil) alias for `:force`
      #
      # @option options [Boolean, nil] :dry_run (nil) do not actually move any
      #   files; only show what would happen (alias: `:n`)
      #
      # @option options [Boolean, nil] :n (nil) alias for `:dry_run`
      #
      # @option options [Boolean, nil] :k (nil) skip move or rename actions which
      #   would lead to an error
      #
      # @return [String] git's stdout from the mv command
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def mv(source, destination, options = {})
        SharedPrivate.assert_valid_opts!(MV_ALLOWED_OPTS, **options)
        Git::Commands::Mv.new(@execution_context).call(*Array(source), destination, verbose: true, **options).stdout
      end

      # Option keys accepted by {#clean}
      #
      # The deprecated `:ff` and `:force_force` keys are handled by
      # {Git::Repository::Staging::Private.migrate_clean_legacy_options} before this
      # whitelist is enforced, so they are intentionally absent here.
      CLEAN_ALLOWED_OPTS = %i[d force f dry_run n quiet q exclude e x X pathspec].freeze
      private_constant :CLEAN_ALLOWED_OPTS

      # Remove untracked files from the working tree
      #
      # @example Remove untracked files
      #   repo.clean({ force: true })
      #
      # @example Remove untracked files and directories
      #   repo.clean({ force: true, d: true })
      #
      # @example Remove untracked and ignored files
      #   repo.clean({ force: true, x: true })
      #
      # @param opts [Hash] options for the clean command
      #
      # @option opts [Boolean, nil] :d (nil) recurse into untracked directories
      #
      # @option opts [Boolean, Integer, nil] :force (nil) force the removal of
      #   untracked files; pass `2` to also remove untracked nested git repositories
      #   (alias: `:f`)
      #
      # @option opts [Boolean, Integer, nil] :f (nil) alias for `:force`
      #
      # @option opts [Boolean, nil] :dry_run (nil) do not actually remove anything,
      #   just show what would be done (alias: `:n`)
      #
      # @option opts [Boolean, nil] :n (nil) alias for `:dry_run`
      #
      # @option opts [Boolean, nil] :quiet (nil) be quiet, only report errors
      #   (alias: `:q`)
      #
      # @option opts [Boolean, nil] :q (nil) alias for `:quiet`
      #
      # @option opts [String, Array<String>] :exclude (nil) use the given exclude
      #   pattern in addition to the standard ignore rules (alias: `:e`)
      #
      # @option opts [String, Array<String>] :e (nil) alias for `:exclude`
      #
      # @option opts [Boolean, nil] :x (nil) don't use the standard ignore rules
      #
      # @option opts [Boolean, nil] :X (nil) remove only files ignored by git
      #
      # @option opts [String, Array<String>] :pathspec (nil) limit cleaning to files
      #   matching the given pathspec(s)
      #
      # @return [String] git's stdout from the clean
      #
      # @raise [ArgumentError] when unsupported options are provided, or when a
      #   deprecated `:ff`/`:force_force` value is not `true`, `false`, or `nil`
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def clean(opts = {})
        opts = Private.migrate_clean_legacy_options(opts)
        SharedPrivate.assert_valid_opts!(CLEAN_ALLOWED_OPTS, **opts)
        Git::Commands::Clean.new(@execution_context).call(**opts).stdout
      end

      # List the files in the working tree that are ignored by git
      #
      # Runs `git ls-files --others --ignored --exclude-standard` and returns the
      # ignored files as repository-relative paths.
      #
      # @example List ignored files
      #   repo.ignored_files #=> ["coverage/index.html", "tmp/cache.db"]
      #
      # @example No ignored files
      #   repo.ignored_files #=> []
      #
      # @return [Array<String>] repository-relative paths of ignored files; empty
      #   when there are none
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def ignored_files
        Git::Commands::LsFiles.new(@execution_context).call(
          others: true, ignored: true, exclude_standard: true
        ).stdout.split("\n").map { |f| Private.unescape_quoted_path(f) }
      end

      # Private helpers local to {Git::Repository::Staging}
      #
      # @api private
      #
      module Private
        module_function

        # Translate deprecated `git clean` option keys into their modern form
        #
        # Maps the legacy `:ff` and `:force_force` boolean options onto the
        # `:force` option, emitting a deprecation warning for each.
        #
        # @param opts [Hash] the caller-provided clean options
        #
        # @option opts [Boolean, nil] :ff (nil) deprecated alias for requesting a
        #   double-force clean
        #
        # @option opts [Boolean, nil] :force_force (nil) deprecated alias for
        #   requesting a double-force clean
        #
        # @option opts [Boolean, Integer, nil] :force (nil) existing force value
        #   merged with deprecated options when present
        #
        # @return [Hash] a new options hash with deprecated keys translated
        #
        # @raise [ArgumentError] when a deprecated value is not `true`, `false`, or `nil`
        #
        def migrate_clean_legacy_options(opts)
          opts = deprecate_clean_option(
            :ff,
            ':ff option is deprecated and will be removed in v6.0.0. Use force: 2 instead.',
            opts
          )

          deprecate_clean_option(
            :force_force,
            ':force_force option is deprecated and will be removed in v6.0.0. Use force: 2 instead.',
            opts
          )
        end

        # Translate a single deprecated clean option key onto `:force`
        #
        # @param key [Symbol] the deprecated option key (`:ff` or `:force_force`)
        #
        # @param message [String] the deprecation message to emit
        #
        # @param opts [Hash] the clean options
        #
        # @option opts [Boolean, nil] :ff (nil) deprecated alias for requesting a
        #   double-force clean
        #
        # @option opts [Boolean, nil] :force_force (nil) deprecated alias for
        #   requesting a double-force clean
        #
        # @option opts [Boolean, Integer, nil] :force (nil) existing force value
        #   updated when the deprecated key is true
        #
        # @return [Hash] a new options hash with the deprecated key removed
        #
        # @raise [ArgumentError] when the deprecated value is not `true`, `false`,
        #   or `nil`
        #
        def deprecate_clean_option(key, message, opts)
          return opts unless opts.key?(key)

          opts = opts.dup
          deprecated_value = opts.delete(key)
          validate_deprecated_clean_option_value!(key, deprecated_value)

          Git::Deprecation.warn(message)
          return opts unless deprecated_value

          opts[:force] = merge_clean_force_option(opts[:force], force_specified: force_option_specified?(opts))
          opts
        end

        # Whether the caller explicitly set a non-nil `:force` value
        #
        # @param opts [Hash] the clean options
        #
        # @option opts [Boolean, Integer, nil] :force (nil) the clean force value
        #   to inspect
        #
        # @return [Boolean] true if `:force` was set to a non-nil value, false
        #   otherwise
        #
        def force_option_specified?(opts)
          opts.key?(:force) && !opts[:force].nil?
        end

        # Validate the value passed to a deprecated clean option
        #
        # @param key [Symbol] the deprecated option key
        #
        # @param value [Object] the value provided for the deprecated key
        #
        # @return [void]
        #
        # @raise [ArgumentError] when `value` is not `true`, `false`, or `nil`
        #
        def validate_deprecated_clean_option_value!(key, value)
          return if value.nil? || value == true || value == false

          raise ArgumentError, "#{key} option only accepts true, false, or nil"
        end

        # Merge a deprecated force request into the existing `:force` value
        #
        # @param existing_force [Boolean, Integer, nil] the caller's `:force` value
        #
        # @param force_specified [Boolean] whether the caller explicitly set `:force`
        #
        # @return [Integer] the resolved `:force` value
        #
        def merge_clean_force_option(existing_force, force_specified: false)
          return 2 unless force_specified

          normalized_force = normalize_clean_force_option(existing_force)

          case normalized_force
          when Integer then merge_integer_clean_force_option(normalized_force)
          when false then 2
          else normalized_force
          end
        end

        # Merge an integer `:force` value with the deprecated force request
        #
        # @param normalized_force [Integer] the caller's normalized `:force` value
        #
        # @return [Integer] the resolved `:force` value
        #
        def merge_integer_clean_force_option(normalized_force)
          return normalized_force if normalized_force < 1

          [normalized_force, 2].max
        end

        # Normalize a `:force` value, coercing `true` to the integer `1`
        #
        # @param value [Boolean, Integer, nil] the `:force` value
        #
        # @return [Integer, Boolean, nil] the normalized value
        #
        def normalize_clean_force_option(value)
          case value
          when true then 1
          else value
          end
        end

        # Unescape a git-quoted path
        #
        # Git wraps paths containing non-ASCII or special characters in
        # double-quotes and octal-escapes each byte. This method strips the
        # surrounding quotes and delegates unescaping to {Git::EscapedPath}.
        #
        # @param path [String] the path as it appears in git output
        #
        # @return [String] the unescaped path
        #
        def unescape_quoted_path(path)
          if path.start_with?('"') && path.end_with?('"')
            Git::EscapedPath.new(path[1..-2]).unescape
          else
            path
          end
        end
      end

      private_constant :Private
    end
  end
end
