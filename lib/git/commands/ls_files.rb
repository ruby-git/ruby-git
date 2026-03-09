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
    class LsFiles < Git::Commands::Base
      arguments do
        literal 'ls-files'
        flag_option :cached
        flag_option :deleted
        flag_option :modified
        flag_option :others
        flag_option :stage
        flag_option :unmerged
        flag_option :ignored
        flag_option :full_name
        flag_option :exclude_standard
        flag_option :error_unmatch
        operand :paths, repeatable: true
      end

      # @!method call(*, **)
      #
      #   Execute the git ls-files command
      #
      #   @overload call(*paths, **options)
      #
      #     @param paths [Array<String>] zero or more file or directory path patterns
      #       to restrict the output to. When empty, lists files in the entire
      #       repository.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :cached (nil) Show all files cached in the
      #       index, i.e. all tracked files. This is the default output when no other
      #       mode option is given.
      #
      #     @option options [Boolean] :deleted (nil) Show files with an unstaged
      #       deletion.
      #
      #     @option options [Boolean] :modified (nil) Show files with an unstaged
      #       modification.
      #
      #     @option options [Boolean] :others (nil) Show other (i.e. untracked) files
      #       in the output.
      #
      #     @option options [Boolean] :stage (nil) Show staged contents' object name,
      #       mode bits, and stage number in the output.
      #
      #     @option options [Boolean] :unmerged (nil) Show information about unmerged
      #       files in the output, but do not show any other tracked files.
      #
      #     @option options [Boolean] :ignored (nil) Show only ignored files in the
      #       output. Must be used with an explicit pathspec or one of the
      #       `:exclude` or `:exclude_standard` options to specify the
      #       ignore patterns.
      #
      #     @option options [Boolean] :full_name (nil) When run from a subdirectory,
      #       output paths relative to the project top directory rather than the
      #       current directory.
      #
      #     @option options [Boolean] :exclude_standard (nil) Add the standard git
      #       exclusions (.git/info/exclude, .gitignore in each directory, and
      #       the user's global exclusion file).
      #
      #     @option options [Boolean] :error_unmatch (nil) If any files do not
      #       appear in the index, treat this as an error and exit with a non-zero
      #       status.
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
