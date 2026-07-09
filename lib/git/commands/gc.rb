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

      # @overload call(**options)
      #
      #     Execute the `git gc` command
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :aggressive (nil) be more thorough at the
      #       expense of increased runtime
      #
      #       When `true`, git gc runs more aggressively to optimize the repository.
      #       The effects are mostly persistent.
      #
      #     @option options [Boolean, nil] :auto (nil) check whether housekeeping is
      #       required before performing any work
      #
      #       When `true`, git gc checks whether housekeeping is needed; if not, it
      #       exits without doing anything.
      #
      #     @option options [Boolean, nil] :detach (nil) run in the background if the
      #       system supports it (`--detach`)
      #
      #       Overrides the `gc.autoDetach` configuration.
      #
      #     @option options [Boolean, nil] :no_detach (nil) run in the foreground
      #       (`--no-detach`)
      #
      #       Overrides the `gc.autoDetach` configuration.
      #
      #     @option options [Boolean, nil] :cruft (nil) pack unreachable objects into a
      #       cruft pack instead of storing them as loose objects (`--cruft`)
      #
      #     @option options [Boolean, nil] :no_cruft (nil) do not create a cruft pack;
      #       store unreachable objects as loose objects (`--no-cruft`)
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
      #     @option options [Boolean, String, nil] :prune (nil) prune loose objects
      #       older than the given date (`--prune`, `--prune=<date>`)
      #
      #       When `true`, passes `--prune` (uses git's default expiry of 2 weeks
      #       ago). When a String, passes `--prune=<date>`.
      #
      #     @option options [Boolean, nil] :no_prune (nil) do not prune any loose
      #       objects (`--no-prune`)
      #
      #     @option options [Boolean, nil] :quiet (nil) suppress all progress reports
      #
      #     @option options [Boolean, nil] :force (nil) force running gc even if
      #       another gc instance may be running on this repository
      #
      #     @option options [Boolean, nil] :keep_largest_pack (nil) repack all packs
      #       except the largest non-cruft pack and those marked with a `.keep` file
      #
      #       When `true`, `gc.bigPackThreshold` is ignored.
      #
      #     @return [Git::CommandLine::Result] the result of calling `git gc`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #     @api public
      #
      def call(*, **)
        super
      end
    end
  end
end
