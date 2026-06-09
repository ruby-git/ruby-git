# frozen_string_literal: true

require 'git/commands/gc'
require 'git/commands/repack'

module Git
  class Repository
    # Facade methods for repository maintenance and optimization operations
    #
    # These methods pack objects, compress history, prune unreachable objects, and
    # otherwise keep the repository in good health.
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Maintenance
      # Repack loose objects into pack files
      #
      # Packs all unpacked objects and removes redundant pack files. This is
      # equivalent to running `git repack -a -d`, which packs all objects into a
      # single pack and deletes any packs that become redundant.
      #
      # This method uses the fixed options `a: true, d: true` (matching the 4.x
      # behavior). No additional options are exposed.
      #
      # @example Repack the repository
      #   repo.repack
      #
      # @return [String] the stdout from `git repack`. Git writes all progress
      #   and summary output to stderr, so the returned string is typically empty.
      #   Returns `String` to match the 4.x public contract (`Git::Lib#command`
      #   returned `result.stdout`).
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def repack
        Git::Commands::Repack.new(@execution_context).call(a: true, d: true).stdout
      end

      # Run garbage collection to optimize and clean up the repository
      #
      # Runs `git gc` to perform housekeeping tasks including object compression,
      # pruning of unreachable objects, and ref packing. This is equivalent to
      # running `git gc --prune --aggressive --auto`.
      #
      # This method uses the fixed options `prune: true, aggressive: true, auto: true`
      # (matching the 4.x behavior). No additional options are exposed.
      #
      # @example Run garbage collection
      #   repo.gc
      #
      # @return [String] the stdout from `git gc`. Git writes all progress
      #   and summary output to stderr, so the returned string is typically empty.
      #   Returns `String` to match the 4.x public contract (`Git::Lib#command`
      #   returned `result.stdout`).
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def gc
        Git::Commands::Gc.new(@execution_context).call(prune: true, aggressive: true, auto: true).stdout
      end
    end
  end
end
