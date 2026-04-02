# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Wrapper for the `git gc` command
    #
    # Runs a number of housekeeping tasks within the current repository, such as
    # compressing file revisions (to reduce disk space and increase performance),
    # removing unreachable objects, packing refs, pruning reflog, rerere metadata
    # or stale working trees.
    #
    # @example Basic usage
    #   gc = Git::Commands::Gc.new(execution_context)
    #   gc.call
    #
    # @example Run only if housekeeping is needed
    #   gc = Git::Commands::Gc.new(execution_context)
    #   gc.call(auto: true)
    #
    # @example Aggressive optimization with custom prune expiry
    #   gc = Git::Commands::Gc.new(execution_context)
    #   gc.call(aggressive: true, prune: 'now')
    #
    # @see https://git-scm.com/docs/git-gc git-gc documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Gc < Git::Commands::Base
      arguments do
        literal 'gc'

        # Optimization behaviour
        flag_option :aggressive
        flag_option :auto

        # Output control
        flag_option %i[quiet q]

        # Pruning
        flag_or_value_option :prune, negatable: true, inline: true

        # Safety / override
        flag_option :force
        flag_option :keep_largest_pack
      end

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Execute the `git gc` command
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :aggressive (nil) be more thorough (increased runtime)
      #
      #       When `true`, git gc runs more aggressively to optimize the repository at
      #       the expense of taking much more time. The effects are mostly persistent.
      #
      #     @option options [Boolean] :auto (nil) check whether any housekeeping is required
      #       before performing any work
      #
      #       When `true`, git gc checks whether housekeeping is needed; if not, it exits
      #       without doing anything.
      #
      #     @option options [Boolean] :quiet (nil) suppress progress reporting
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean, String] :prune (nil) prune loose objects older than date
      #
      #       When `true`, passes `--prune` (uses git's default expiry of 2 weeks ago). When
      #       a string, passes `--prune=<date>`. When `false`, passes `--no-prune` to skip
      #       pruning entirely. When `nil`, the option is omitted and git uses its configured
      #       default.
      #
      #     @option options [Boolean] :force (nil) force running gc even if there may be
      #       another gc running on this repository
      #
      #     @option options [Boolean] :keep_largest_pack (nil) repack all other packs except
      #       the largest pack and those marked with a `.keep` file
      #
      #       When `true`, `gc.bigPackThreshold` is ignored.
      #
      #     @return [Git::CommandLineResult] the result of calling `git gc`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if the command returns a non-zero exit status
    end
  end
end
