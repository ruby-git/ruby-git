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
    # @see https://git-scm.com/docs/git-checkout-index git-checkout-index
    #
    # @api private
    #
    # @example Copy all indexed files to the working directory
    #   checkout_index = Git::Commands::CheckoutIndex.new(execution_context)
    #   checkout_index.call(all: true)
    #
    # @example Force-overwrite existing files
    #   checkout_index.call(all: true, force: true)
    #
    # @example Write files under an output prefix directory
    #   checkout_index.call(all: true, prefix: 'output/')
    #
    # @example Checkout a specific file
    #   checkout_index.call('path/to/file.txt')
    #
    # @example Checkout a specific file with force
    #   checkout_index.call('path/to/file.txt', force: true)
    #
    class CheckoutIndex < Git::Commands::Base
      arguments do
        literal 'checkout-index'
        flag_option %i[index u]
        flag_option %i[all a]
        flag_option %i[force f]
        flag_option %i[no_create n]
        value_option :prefix, inline: true
        value_option :stage, inline: true
        flag_option :temp
        flag_option :ignore_skip_worktree_bits
        operand :file, required: false, repeatable: true, separator: '--'

        allowed_values :stage, in: %w[1 2 3 all]
        conflicts :all, :file
      end

      # @!method call(*, **)
      #
      #   Execute the git checkout-index command
      #
      #   @overload call(*file, **options)
      #
      #     @param file [Array<String>] Zero or more file paths to check out.
      #       Appended after `--` to distinguish them from options. When empty, no
      #       path separator is appended (use `:all` to check out everything).
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :index (nil) Update the index rather than
      #       checking out files to the working directory. Alias: :u
      #
      #     @option options [Boolean] :all (nil) Check out all files in the index.
      #       Alias: :a
      #
      #     @option options [Boolean] :force (nil) Force checkout even if
      #       file already exists in the output location. Alias: :f
      #
      #     @option options [Boolean] :no_create (nil) Don't checkout new files,
      #       only refresh files already checked out. Alias: :n
      #
      #     @option options [String] :prefix (nil) Write the content to files under
      #       the given directory prefix instead of the working directory root
      #
      #     @option options [String] :stage (nil) Check out from the named stage:
      #       a number (1, 2, or 3) or the string 'all'
      #
      #     @option options [Boolean] :temp (nil) Instead of checking the files out,
      #       write the content to temporary files near the target location
      #
      #     @option options [Boolean] :ignore_skip_worktree_bits (nil) Ignore the
      #       skip-worktree bits when checking out files
      #
      #     @return [Git::CommandLineResult] the result of the command
      #
      #     @raise [Git::FailedError] if the git command fails
    end
  end
end
