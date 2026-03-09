# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git ls-files` command
    #
    # Shows information about files in the index and the working tree. By default
    # lists all cached (tracked) files. When combined with mode options such as
    # `--stage`, outputs additional metadata such as object mode, sha, and stage
    # number.
    #
    # @see https://git-scm.com/docs/git-ls-files git-ls-files
    # @see Git::Commands
    #
    # @api private
    #
    # @example List all tracked files
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   result = ls_files.call
    #
    # @example Show staged (index) info for all files
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   result = ls_files.call(stage: true)
    #
    # @example Show staged info for files under a path
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   result = ls_files.call('lib/', stage: true)
    #
    # @example Show only untracked files using standard excludes
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   result = ls_files.call(others: true, exclude_standard: true)
    #
    # @example Exclude files matching a pattern
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   result = ls_files.call(others: true, exclude: '*.log', exclude_standard: true)
    #
    class LsFiles < Git::Commands::Base
      arguments do
        literal 'ls-files'

        # Output format flags
        flag_option :z
        flag_option :t
        flag_option :v
        flag_option :f

        # Mode selections (what files to show)
        flag_option %i[cached c]
        flag_option %i[deleted d]
        flag_option %i[others o]
        flag_option %i[ignored i]
        flag_option %i[stage s]
        flag_option :directory
        flag_option :no_empty_directory
        flag_option %i[unmerged u]
        flag_option %i[killed k]
        flag_option %i[modified m]
        flag_option :resolve_undo
        flag_option :deduplicate
        flag_option :eol

        # Exclude patterns
        value_option %i[exclude x], inline: true, repeatable: true
        value_option %i[exclude_from X], inline: true, repeatable: true
        value_option :exclude_per_directory, inline: true
        flag_option :exclude_standard

        # Error handling and tree lookup
        flag_option :error_unmatch
        value_option :with_tree, inline: true

        # Output customisation
        flag_option :full_name
        flag_option :recurse_submodules
        flag_or_value_option :abbrev, inline: true
        value_option :format, inline: true
        flag_option :sparse
        flag_option :debug

        operand :file, repeatable: true
      end

      # @!method call(*, **)
      #
      #   Execute the git ls-files command
      #
      #   @overload call(*file, **options)
      #
      #     @param file [Array<String>] zero or more file or directory paths to
      #       restrict the output to. When empty, lists files in the entire
      #       repository.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :z (nil) Use NUL as the line terminator and
      #       do not quote filenames.
      #
      #     @option options [Boolean] :t (nil) Show status tags together with
      #       filenames (H tracked, S skip-worktree, M unmerged, R removal,
      #       C change, K kill, ? untracked, U resolve-undo).
      #
      #     @option options [Boolean] :v (nil) Like `:t`, but use lowercase letters
      #       for files that are marked as assume-unchanged.
      #
      #     @option options [Boolean] :f (nil) Like `:t`, but use lowercase letters
      #       for files that are marked as fsmonitor valid.
      #
      #     @option options [Boolean] :cached (nil) Show all files cached in the
      #       index, i.e. all tracked files. This is the default output when no mode
      #       option is given.
      #
      #       Alias: :c
      #
      #     @option options [Boolean] :deleted (nil) Show files with an unstaged
      #       deletion.
      #
      #       Alias: :d
      #
      #     @option options [Boolean] :others (nil) Show other (i.e. untracked)
      #       files in the output.
      #
      #       Alias: :o
      #
      #     @option options [Boolean] :ignored (nil) Show only ignored files in the
      #       output. Must be used with either an explicit `:cached`/`:others` and
      #       at least one `--exclude*` option.
      #
      #       Alias: :i
      #
      #     @option options [Boolean] :stage (nil) Show staged contents' mode bits,
      #       object name, and stage number in the output.
      #
      #       Alias: :s
      #
      #     @option options [Boolean] :directory (nil) Show just the directory name
      #       (with a trailing slash) when a whole directory is classified as
      #       "other". Has no effect without `:others`.
      #
      #     @option options [Boolean] :no_empty_directory (nil) Do not list empty
      #       directories. Has no effect without `:directory`.
      #
      #     @option options [Boolean] :unmerged (nil) Show information about unmerged
      #       files in the output, but do not show any other tracked files.
      #
      #       Alias: :u
      #
      #     @option options [Boolean] :killed (nil) Show untracked files on the
      #       filesystem that need to be removed due to file/directory conflicts for
      #       tracked files to be able to be written to the filesystem.
      #
      #       Alias: :k
      #
      #     @option options [Boolean] :modified (nil) Show files with an unstaged
      #       modification.
      #
      #       Alias: :m
      #
      #     @option options [Boolean] :resolve_undo (nil) Show files having
      #       resolve-undo information in the index together with their resolve-undo
      #       information.
      #
      #     @option options [Boolean] :deduplicate (nil) When only filenames are
      #       shown, suppress duplicates that may come from having multiple stages
      #       during a merge, or from giving `:deleted` and `:modified` at the same
      #       time. Has no effect when `:t`, `:unmerged`, or `:stage` is in use.
      #
      #     @option options [Boolean] :eol (nil) Show end-of-line info
      #       (`<eolinfo>` and `<eolattr>`) for each file. Cannot be combined with
      #       `:format`.
      #
      #     @option options [String, Array<String>] :exclude (nil) Skip untracked
      #       files matching the given shell wildcard pattern. May be given multiple
      #       times as an Array. Use `:exclude_standard` to apply standard ignore
      #       rules instead.
      #
      #       Alias: :x
      #
      #     @option options [String, Array<String>] :exclude_from (nil) Read exclude
      #       patterns from the given file (one per line). May be given multiple
      #       times as an Array.
      #
      #       Alias: :X
      #
      #     @option options [String] :exclude_per_directory (nil) Read additional
      #       exclude patterns from the named file in each directory git ls-files
      #       examines (typically `.gitignore`).
      #
      #     @option options [Boolean] :exclude_standard (nil) Add the standard git
      #       exclusions: `.git/info/exclude`, `.gitignore` in each directory, and
      #       the user's global exclusion file.
      #
      #     @option options [Boolean] :error_unmatch (nil) If any given file does not
      #       appear in the index, treat this as an error and exit with a non-zero
      #       status.
      #
      #     @option options [String] :with_tree (nil) When using `:error_unmatch`,
      #       pretend that files removed from the index since the named tree-ish are
      #       still present. Not meaningful with `:stage` or `:unmerged`.
      #
      #     @option options [Boolean] :full_name (nil) Output paths relative to the
      #       project top directory even when run from a subdirectory.
      #
      #     @option options [Boolean] :recurse_submodules (nil) Recursively call
      #       ls-files on each active submodule. Only `:cached` and `:stage` modes
      #       are currently supported.
      #
      #     @option options [Boolean, String] :abbrev (nil) Show abbreviated object
      #       names. When given a string value `n`, shows the shortest prefix of at
      #       least `n` hex digits that uniquely identifies the object.
      #
      #     @option options [String] :format (nil) Output each file using the given
      #       interpolation format string (e.g. `'%(objectname) %(path)'`). Cannot be
      #       combined with `:stage`, `:others`, `:killed`, `:t`, `:resolve_undo`, or
      #       `:eol`.
      #
      #     @option options [Boolean] :sparse (nil) When the index is sparse, show
      #       sparse directories without expanding to the contained files.
      #
      #     @option options [Boolean] :debug (nil) After each line, add extra data
      #       about the cache entry for manual inspection.
      #
      #     @return [Git::CommandLineResult] the result of calling `git ls-files`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if the command returns a non-zero exit status
      #
    end
  end
end
