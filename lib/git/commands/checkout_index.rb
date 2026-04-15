# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git checkout-index` command
    #
    # This command copies all files listed in the index to the working directory
    # (not overwriting existing files). It is typically used to populate a new
    # working directory from the current index, optionally scoped to a specific
    # path or prefix.
    #
    # @example Typical usage
    #   checkout_index = Git::Commands::CheckoutIndex.new(execution_context)
    #   checkout_index.call(all: true)
    #   checkout_index.call(all: true, force: true)
    #   checkout_index.call('path/to/file.txt')
    #   checkout_index.call(all: true, prefix: 'output/')
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-checkout-index/2.53.0
    #
    # @see https://git-scm.com/docs/git-checkout-index git-checkout-index
    #
    # @see Git::Commands
    #
    # @api private
    #
    class CheckoutIndex < Git::Commands::Base
      arguments do
        literal 'checkout-index'
        flag_option %i[index u]
        flag_option %i[quiet q]
        flag_option %i[all a]
        flag_option %i[force f]
        flag_option %i[no_create n]
        value_option :prefix, inline: true
        value_option :stage, inline: true
        flag_option :temp
        flag_option :ignore_skip_worktree_bits
        end_of_options
        operand :file, required: false, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*file, **options)
      #
      #     Execute the `git checkout-index` command
      #
      #     @param file [Array<String>] zero or more file paths to check out
      #
      #       When empty, no files are checked out individually (use `:all` to check
      #       out everything).
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :index (false) update stat information for the
      #       checked out entries in the index file
      #
      #       Alias: `:u`
      #
      #     @option options [Boolean] :quiet (false) suppress messages when files
      #       exist or are not in the index
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean] :all (false) check out all files in the index
      #
      #       Alias: `:a`
      #
      #     @option options [Boolean] :force (false) force overwrite of existing files
      #
      #       Alias: `:f`
      #
      #     @option options [Boolean] :no_create (false) don't checkout new files,
      #       only refresh files already checked out
      #
      #       Alias: `:n`
      #
      #     @option options [String] :prefix (nil) write file content under the given
      #       directory prefix instead of the working directory root
      #
      #     @option options [String] :stage (nil) check out from the named stage
      #
      #       Pass `'1'`, `'2'`, or `'3'` for a specific stage number, or `'all'` to
      #       check out all stages (automatically implies `--temp`).
      #
      #     @option options [Boolean] :temp (false) write file content to temporary
      #       files near the target location instead of checking them out
      #
      #     @option options [Boolean] :ignore_skip_worktree_bits (false) check out
      #       all files, including those with the skip-worktree bit set
      #
      #     @return [Git::CommandLineResult] the result of calling `git checkout-index`
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
