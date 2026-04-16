# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git ls-files` command.
    #
    # This command shows information about files in the index and the working tree.
    # It is used to list tracked, untracked, ignored, and staged files.
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
    # @note `arguments` block audited against https://git-scm.com/docs/git-ls-files/2.53.0
    #
    # @see https://git-scm.com/docs/git-ls-files git-ls-files documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class LsFiles < Git::Commands::Base
      arguments do
        literal 'ls-files'
        flag_option :z
        flag_option :t
        flag_option :v
        flag_option :f
        flag_option %i[cached c]
        flag_option %i[deleted d]
        flag_option %i[others o]
        flag_option %i[ignored i]
        flag_option %i[stage s]
        flag_option %i[unmerged u]
        flag_option %i[killed k]
        flag_option %i[modified m]
        flag_option :resolve_undo
        flag_option :directory
        flag_option :no_empty_directory
        flag_option :eol
        flag_option :deduplicate
        value_option %i[exclude x], inline: true
        value_option %i[exclude_from X], inline: true
        value_option :exclude_per_directory, inline: true
        flag_option :exclude_standard
        flag_option :error_unmatch
        value_option :with_tree, inline: true
        flag_option :full_name
        flag_option :recurse_submodules
        flag_or_value_option :abbrev, inline: true
        flag_option :debug
        flag_option :sparse
        value_option :format, inline: true

        end_of_options

        operand :file, repeatable: true

        execution_option :chdir
      end

      # @!method call(*, **)
      #
      #   @overload call(*file, **options)
      #
      #     Execute the `git ls-files` command.
      #
      #     @param file [Array<String>] paths to limit file listing
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :z (false) use NUL line termination and do not quote filenames
      #
      #     @option options [Boolean] :t (false) show status tags together with filenames
      #
      #     @option options [Boolean] :v (false) similar to `-t` but use lowercase letters for files
      #       that are marked as assume unchanged
      #
      #     @option options [Boolean] :f (false) similar to `-t` but use lowercase letters for files
      #       that are marked as fsmonitor valid
      #
      #     @option options [Boolean] :cached (false) show all files cached in the index
      #
      #       Alias: :c
      #
      #     @option options [Boolean] :deleted (false) show files with an unstaged deletion
      #
      #       Alias: :d
      #
      #     @option options [Boolean] :others (false) show other (i.e. untracked) files in the output
      #
      #       Alias: :o
      #
      #     @option options [Boolean] :ignored (false) show only ignored files in the output
      #
      #       Must be used with either `:cached` or `:others`. When used with `:cached`, shows only
      #       cached files matching an exclude pattern. When used with `:others`, shows only
      #       untracked files matched by an exclude pattern.
      #
      #       Alias: :i
      #
      #     @option options [Boolean] :stage (false) show object name, mode bits, and stage number
      #
      #       Alias: :s
      #
      #     @option options [Boolean] :unmerged (false) show information about unmerged files
      #
      #       Alias: :u
      #
      #     @option options [Boolean] :killed (false) show untracked files that need to be removed
      #       due to file/directory conflicts for tracked files
      #
      #       Alias: :k
      #
      #     @option options [Boolean] :modified (false) show files with an unstaged modification
      #
      #       Alias: :m
      #
      #     @option options [Boolean] :resolve_undo (false) show files having resolve-undo information
      #
      #     @option options [Boolean] :directory (false) show just the directory name (with trailing
      #       slash) when a whole directory is classified as "other"
      #
      #     @option options [Boolean] :no_empty_directory (false) do not list empty directories
      #
      #     @option options [Boolean] :eol (false) show EOL and encoding attributes of files
      #
      #     @option options [Boolean] :deduplicate (false) suppress duplicate filenames when showing
      #       only filenames
      #
      #     @option options [String] :exclude (nil) skip untracked files matching the given pattern
      #
      #       Alias: :x
      #
      #     @option options [String] :exclude_from (nil) read exclude patterns from the given file
      #
      #       Alias: :X
      #
      #     @option options [String] :exclude_per_directory (nil) read additional exclude patterns
      #       from the named file in each directory
      #
      #     @option options [Boolean] :exclude_standard (false) add the standard git exclusions
      #
      #     @option options [Boolean] :error_unmatch (false) treat unmatched files as an error
      #
      #     @option options [String] :with_tree (nil) pretend paths removed since the named
      #       tree-ish are still present when using `--error-unmatch`
      #
      #     @option options [Boolean] :full_name (false) force paths to be output relative to the
      #       project top-level directory
      #
      #     @option options [Boolean] :recurse_submodules (false) recursively calls ls-files on each
      #       active submodule in the repository
      #
      #     @option options [Boolean, Integer, String] :abbrev (nil) show only a partial prefix of the
      #       object name; pass `true` for the default number of hex digits, or an Integer or String
      #       for a specific prefix length (e.g., `abbrev: 10` or `abbrev: "10"`)
      #
      #     @option options [Boolean] :debug (false) after each filename, output raw index information
      #       (ctime data, mtime data, dev, ino, uid, gid, size, flags, flagsx)
      #
      #     @option options [Boolean] :sparse (false) if the index is sparse, show the sparse directory
      #       entries rather than expanding to the contained files
      #
      #     @option options [String] :format (nil) a string that interpolates %(fieldname) from
      #       the index entry for each file
      #
      #     @option options [String] :chdir (nil) run the command from the specified directory
      #
      #     @return [Git::CommandLineResult] the result of calling `git ls-files`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
