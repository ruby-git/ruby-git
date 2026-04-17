# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git rm` command
    #
    # This command removes files from the working tree and from the index.
    #
    # @example Remove a tracked file
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('file.txt')
    #
    # @example Remove multiple files
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('file1.txt', 'file2.txt')
    #
    # @example Remove a directory recursively
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('directory', r: true)
    #
    # @example Remove from the index only (keep working tree copy)
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('file.txt', cached: true)
    #
    # @example Force removal of modified files
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('modified_file.txt', force: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-rm/2.53.0
    #
    # @see https://git-scm.com/docs/git-rm git-rm
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Rm < Git::Commands::Base
      arguments do
        literal 'rm'
        flag_option %i[force f]
        flag_option %i[dry_run n]
        flag_option :r
        flag_option :cached
        flag_option :ignore_unmatch
        flag_option :sparse
        flag_option %i[quiet q]
        value_option :pathspec_from_file, inline: true
        flag_option :pathspec_file_nul
        end_of_options
        operand :pathspec, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*pathspec, **options)
      #
      #     Execute the git rm command
      #
      #     @param pathspec [Array<String>] files or directories to be removed from the
      #       repository (relative to the worktree root)
      #
      #       At least one positional pathspec or the `:pathspec_from_file` option must
      #       be provided; git will fail at runtime if neither is given.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :force (false) override the up-to-date check and
      #       remove files with local modifications
      #
      #       Alias: :f
      #
      #     @option options [Boolean] :dry_run (false) do not actually remove any files;
      #       instead, just show if they exist in the index and would otherwise be removed
      #       by the command
      #
      #       Alias: :n
      #
      #     @option options [Boolean] :r (false) allow recursive removal when a leading
      #       directory name is given
      #
      #     @option options [Boolean] :cached (false) only remove from the index, keeping
      #       the working tree files
      #
      #     @option options [Boolean] :ignore_unmatch (false) exit with a zero status
      #       even if no files matched
      #
      #     @option options [Boolean] :sparse (false) allow updating index entries outside
      #       of the sparse-checkout cone
      #
      #     @option options [Boolean] :quiet (false) suppress the one-line-per-file output
      #
      #       Alias: :q
      #
      #     @option options [String] :pathspec_from_file (nil) read pathspec from the
      #       given file, one pathspec element per line; pass `-` to read from standard
      #       input
      #
      #     @option options [Boolean] :pathspec_file_nul (false) when used with
      #       `:pathspec_from_file`, separate pathspec elements with NUL instead of
      #       newlines
      #
      #     @return [Git::CommandLineResult] the result of calling `git rm`
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
