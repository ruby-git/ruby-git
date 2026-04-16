# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git gc` command
    #
    # Runs a number of housekeeping tasks within the current repository, such as
    # compressing file revisions (to reduce disk space and increase performance),
    # removing unreachable objects, packing refs, pruning reflog, rerere metadata
    # or stale working trees.
    #
    # @example Typical usage
    #   gc = Git::Commands::Gc.new(execution_context)
    #   gc.call
    #   gc.call(auto: true)
    #   gc.call(aggressive: true, prune: 'now')
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-gc/2.53.0
    #
    # @see https://git-scm.com/docs/git-gc git-gc
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Gc < Git::Commands::Base
      arguments do
        literal 'gc'

        # Optimization
        flag_option :aggressive
        flag_option :auto

        # Background
        flag_option :detach, negatable: true

        # Cruft packs
        flag_option :cruft, negatable: true
        value_option :max_cruft_size, inline: true
        value_option :expire_to, inline: true

        # Pruning
        flag_or_value_option :prune, negatable: true, inline: true

        # Output control
        flag_option :quiet

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
      #     @option options [Boolean] :aggressive (false) be more thorough at the
      #       expense of increased runtime
      #
      #       When `true`, git gc runs more aggressively to optimize the repository.
      #       The effects are mostly persistent.
      #
      #     @option options [Boolean] :auto (false) check whether housekeeping is
      #       required before performing any work
      #
      #       When `true`, git gc checks whether housekeeping is needed; if not, it
      #       exits without doing anything.
      #
      #     @option options [Boolean] :detach (nil) run in the background if the
      #       system supports it
      #
      #       When `true`, passes `--detach`. When `false`, passes `--no-detach`.
      #       Overrides the `gc.autoDetach` configuration. When `nil`, the option
      #       is omitted.
      #
      #     @option options [Boolean] :cruft (nil) pack unreachable objects into a
      #       cruft pack instead of storing them as loose objects
      #
      #       When `true`, passes `--cruft`. When `false`, passes `--no-cruft`.
      #       When `nil`, the option is omitted and git uses its configured default.
      #
      #     @option options [String] :max_cruft_size (nil) limit the size of new
      #       cruft packs to at most `<n>` bytes when packing unreachable objects
      #
      #       Overrides any value specified via `gc.maxCruftSize` configuration.
      #       Maps to `--max-cruft-size=<n>`.
      #
      #     @option options [String] :expire_to (nil) write a cruft pack containing
      #       pruned objects (if any) to the given directory
      #
      #       Only has an effect when used together with `:cruft`. Maps to
      #       `--expire-to=<dir>`.
      #
      #     @option options [Boolean, String] :prune (nil) prune loose objects older
      #       than the given date
      #
      #       When `true`, passes `--prune` (uses git's default expiry of 2 weeks
      #       ago). When a String, passes `--prune=<date>`. When `false`, passes
      #       `--no-prune` to skip pruning entirely. When `nil`, the option is
      #       omitted and git uses its configured default.
      #
      #     @option options [Boolean] :quiet (false) suppress all progress reports
      #
      #     @option options [Boolean] :force (false) force running gc even if
      #       another gc instance may be running on this repository
      #
      #     @option options [Boolean] :keep_largest_pack (false) repack all packs
      #       except the largest non-cruft pack and those marked with a `.keep` file
      #
      #       When `true`, `gc.bigPackThreshold` is ignored.
      #
      #     @return [Git::CommandLineResult] the result of calling `git gc`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #     @api public
    end
  end
end
