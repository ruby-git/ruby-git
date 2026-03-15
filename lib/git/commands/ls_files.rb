# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git ls-files` command
    #
    # This command shows information about files in the index and the working tree.
    # It is used to list tracked, untracked, ignored, and staged files.
    #
    # @see https://git-scm.com/docs/git-ls-files git-ls-files
    #
    # @api private
    #
    # @example List staged files with stage info
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   ls_files.call('.', stage: true)
    #
    # @example List untracked files not ignored
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   ls_files.call(others: true, exclude_standard: true)
    #
    # @example List ignored files
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   ls_files.call(others: true, ignored: true, exclude_standard: true)
    #
    # @example List untracked files in a specific directory
    #   ls_files = Git::Commands::LsFiles.new(execution_context)
    #   ls_files.call(others: true, exclude_standard: true, chdir: '/path/to/workdir')
    #
    class LsFiles < Git::Commands::Base
      arguments do
        literal 'ls-files'
        flag_option :z                                     # -z
        flag_option :t                                     # -t
        flag_option :v                                     # -v
        flag_option :f                                     # -f
        flag_option %i[cached c]                           # --cached / -c
        flag_option %i[deleted d]                          # --deleted / -d
        flag_option %i[others o]                           # --others / -o
        flag_option %i[ignored i]                          # --ignored / -i
        flag_option %i[stage s]                            # --stage / -s
        flag_option %i[unmerged u]                         # --unmerged / -u
        flag_option %i[killed k]                           # --killed / -k
        flag_option %i[modified m]                         # --modified / -m
        flag_option :resolve_undo                          # --resolve-undo
        flag_option :directory                             # --directory
        flag_option :no_empty_directory                    # --no-empty-directory
        flag_option :eol                                   # --eol
        flag_option :sparse                                # --sparse
        flag_option :deduplicate                           # --deduplicate
        value_option %i[exclude x], inline: true           # --exclude=<pattern> / -x
        value_option %i[exclude_from X], inline: true      # --exclude-from=<file> / -X
        value_option :exclude_per_directory, inline: true  # --exclude-per-directory=<file>
        flag_option :exclude_standard                      # --exclude-standard
        flag_option :error_unmatch                         # --error-unmatch
        value_option :with_tree, inline: true              # --with-tree=<tree-ish>
        flag_option :full_name                             # --full-name
        flag_option :recurse_submodules                    # --recurse-submodules
        flag_or_value_option :abbrev, inline: true         # --abbrev[=<n>]
        flag_option :debug                                 # --debug
        value_option :format, inline: true                 # --format=<format>

        end_of_options                                     # --

        operand :file, repeatable: true                    # [<file>...]

        execution_option :chdir                            # NOT a git flag — routes to process spawn options only
      end

      # @!method call(*, **)
      #
      #   @overload call(*file, **options)
      #
      #     Execute the git ls-files command
      #
      #     @param file [Array<String>] Paths to limit file listing
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :z (nil) Use NUL line termination and do not quote filenames
      #
      #     @option options [Boolean] :t (nil) Show status tags together with filenames
      #
      #     @option options [Boolean] :v (nil) Similar to -t but use lowercase letters for files
      #       that are marked as assume unchanged
      #
      #     @option options [Boolean] :f (nil) Similar to -v but use lowercase letters for files
      #       that are marked as fsmonitor valid
      #
      #     @option options [Boolean] :cached (nil) Show all files cached in the index
      #
      #       Alias: :c
      #
      #     @option options [Boolean] :deleted (nil) Show files with an unstaged deletion
      #
      #       Alias: :d
      #
      #     @option options [Boolean] :others (nil) Show other (i.e. untracked) files in the output
      #
      #       Alias: :o
      #
      #     @option options [Boolean] :ignored (nil) Show only ignored files in the output
      #
      #       Requires `:others` to be set to show only untracked ignored files, or
      #       use with named patterns to show ignored tracked files.
      #
      #       Alias: :i
      #
      #     @option options [Boolean] :stage (nil) Show object name, mode bits, and stage number
      #
      #       Alias: :s
      #
      #     @option options [Boolean] :unmerged (nil) Show information about unmerged files
      #
      #       Alias: :u
      #
      #     @option options [Boolean] :killed (nil) Show untracked files that need to be removed
      #       due to file/directory conflicts for tracked files
      #
      #       Alias: :k
      #
      #     @option options [Boolean] :modified (nil) Show files with an unstaged modification
      #
      #       Alias: :m
      #
      #     @option options [Boolean] :resolve_undo (nil) Show files having resolve-undo information
      #
      #     @option options [Boolean] :directory (nil) Show just the directory name (with trailing
      #       slash) when a whole directory is classified as "other"
      #
      #     @option options [Boolean] :no_empty_directory (nil) Do not list empty directories
      #
      #     @option options [Boolean] :eol (nil) Show EOL and encoding attributes of files
      #
      #     @option options [Boolean] :sparse (nil) If the index is sparse, show the sparse directory
      #       entries rather than expanding to the contained files
      #
      #     @option options [Boolean] :deduplicate (nil) Suppress duplicate filenames when showing
      #       only filenames
      #
      #     @option options [String] :exclude (nil) Skip untracked files matching the given pattern
      #
      #       Alias: :x
      #
      #     @option options [String] :exclude_from (nil) Read exclude patterns from the given file
      #
      #       Alias: :X
      #
      #     @option options [String] :exclude_per_directory (nil) Read additional exclude patterns
      #       from the named file in each directory
      #
      #     @option options [Boolean] :exclude_standard (nil) Add the standard git exclusions
      #
      #     @option options [Boolean] :error_unmatch (nil) Treat unmatched files as an error
      #
      #     @option options [String] :with_tree (nil) Pretend paths removed since the named
      #       tree-ish are still present when using --error-unmatch
      #
      #     @option options [Boolean] :full_name (nil) Force paths to be output relative to the
      #       project top-level directory
      #
      #     @option options [Boolean] :recurse_submodules (nil) Recursively calls ls-files on each
      #       active submodule in the repository
      #
      #     @option options [Boolean, Integer, String] :abbrev (nil) Show only a partial prefix of the
      #       object name; pass true for the default number of hex digits, or an Integer or String
      #       for a specific prefix length (e.g., abbrev: 10 or abbrev: "10")
      #
      #     @option options [Boolean] :debug (nil) After each filename, output raw index information
      #       (ctime data, mtime data, dev, ino, uid, gid, size, flags, flagsx)
      #
      #     @option options [String] :format (nil) A string that interpolates %(fieldname) from
      #       the index entry for each file
      #
      #     @option options [String] :chdir (nil) Run the command from the specified directory
      #
      #     @return [Git::CommandLineResult] the result of calling `git ls-files`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
