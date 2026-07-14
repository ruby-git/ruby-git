# frozen_string_literal: true

require 'tempfile'
require 'git/commands/diff'
require 'git/commands/merge/start'
require 'git/commands/merge_base'
require 'git/commands/revert/start'
require 'git/commands/show'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for merge operations: merging branches into the current branch,
    # and finding common ancestors between commits
    #
    # Included by {Git::Repository}.
    #
    # @api private
    #
    module Merging
      # Option keys accepted by {#merge}
      #
      # Derived from the 4.x option map for `Git::Lib#merge`.
      MERGE_ALLOWED_OPTS = %i[no_commit no_ff m message].freeze
      private_constant :MERGE_ALLOWED_OPTS

      # Option keys accepted by {#merge_base}
      #
      # Derived from the 4.x option map for `Git::Lib#merge_base`.
      MERGE_BASE_ALLOWED_OPTS = %i[octopus independent fork_point all].freeze
      private_constant :MERGE_BASE_ALLOWED_OPTS

      # Merge one or more branches into the current branch
      #
      # The merge commit message may be given by the message positional argument, the
      # `:message` option, or the `:m` option; if more than one is provided, the
      # precedence is positional argument > `:message` > `:m`.
      #
      # @example Merge a single branch
      #   repo.merge('feature')
      #
      # @example Merge a branch with a no-fast-forward commit message
      #   repo.merge('feature', 'Merge feature into main', no_ff: true)
      #
      # @example Octopus merge of multiple branches
      #   repo.merge(%w[feature-a feature-b])
      #
      # @example Merge without committing
      #   repo.merge('feature', nil, no_commit: true)
      #
      # @param branch [String, Array<String>, #to_s] the branch or branches to merge
      #   into the current branch
      #
      #   When an Array is given, an octopus merge is performed; a {Git::Branch}
      #   object is coerced to a String via `#to_s`.
      #
      # @param message [String, nil] optional commit message for the merge commit
      #
      #   Translated to the `-m` flag internally. For fast-forward merges git ignores
      #   this value; use `no_ff: true` to ensure a merge commit is created and the
      #   message is recorded.
      #
      # @param opts [Hash] additional options forwarded to `git merge`
      #
      # @option opts [Boolean, nil] :no_commit (nil) stop before creating the merge commit
      #   (`--no-commit`)
      #
      # @option opts [Boolean, nil] :no_ff (nil) create a merge commit even when
      #   fast-forward is possible (`--no-ff`)
      #
      # @option opts [String] :message (nil) commit message
      #
      #   Prefer the `:m` option instead of this one. Translated to the `-m` flag.
      #   Identical to the positional `message` argument and the `:m` option.
      #
      # @option opts [String] :m (nil) commit message (`-m` flag)
      #
      # @return [String] git's stdout from the merge command
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def merge(branch, message = nil, opts = {})
        SharedPrivate.assert_valid_opts!(MERGE_ALLOWED_OPTS, **opts)

        # Dup so callers who reuse the same opts hash are not affected
        opts = opts.dup

        # Merge positional message into opts so the rest of the logic is uniform
        opts[:message] = message if message

        # git merge uses -m, not --message; translate the key
        opts[:m] = opts.delete(:message) if opts.key?(:message)

        branches = Array(branch).map(&:to_s)
        Git::Commands::Merge::Start.new(@execution_context).call(*branches, no_edit: true, **opts).stdout
      end

      # Find common ancestor commit(s) for use in a merge
      #
      # @example Find the common ancestor of two branches
      #   repo.merge_base('main', 'feature') #=> ["abc123def456..."]
      #
      # @example Find all common ancestors of two branches
      #   repo.merge_base('branch-a', 'branch-b', all: true)
      #
      # @example Find the fork point of a branch (consults the reflog)
      #   repo.merge_base('main', 'feature', fork_point: true)
      #
      # @example Find independent commits not reachable from each other
      #   repo.merge_base('abc1234', 'main', 'feature', independent: true)
      #
      # @overload merge_base(*commits, options = {})
      #
      #   @param commits [Array<String>] two or more commit SHAs, branch names,
      #     or refs to find the common ancestor(s) of
      #
      #   @param options [Hash] merge-base options
      #
      #   @option options [Boolean, nil] :octopus (nil) compute the best common
      #     ancestor for an n-way merge (intersection of all merge bases)
      #
      #   @option options [Boolean, nil] :independent (nil) list commits not
      #     reachable from any other; useful for finding minimal merge points
      #
      #   @option options [Boolean, nil] :fork_point (nil) find the fork point
      #     where a branch diverged from another, consulting the reflog
      #
      #   @option options [Boolean, nil] :all (nil) output all merge bases instead
      #     of just the first when multiple equally good bases exist
      #
      #   @return [Array<String>] commit SHAs of the common ancestor(s); empty
      #     when no common ancestor exists or `--fork-point` finds none
      #
      #   @raise [ArgumentError] when unsupported options are provided
      #
      #   @raise [Git::FailedError] when `git merge-base` exits outside the
      #     allowed range (exit code > 1)
      #
      def merge_base(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        SharedPrivate.assert_valid_opts!(MERGE_BASE_ALLOWED_OPTS, **opts)
        result = Git::Commands::MergeBase.new(@execution_context).call(*args, **opts)
        result.stdout.lines.map(&:strip).reject(&:empty?)
      end

      # Return the paths of files with unresolved merge conflicts
      #
      # @example List conflicting files after a failed merge
      #   paths = repo.unmerged
      #   # => ["config/settings.rb", "lib/git/base.rb"]
      #   paths.each { |path| puts "Conflict in #{path}" }
      #
      # @return [Array<String>] repository-relative paths of files with unresolved
      #   merge conflicts; empty array when the working tree has no conflicts
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 2)
      #
      # @see #each_conflict
      #
      def unmerged
        Private.unmerged_paths(@execution_context)
      end

      # Iterate over files with merge conflicts, yielding conflict details for each
      #
      # For each unmerged file, the staged content for both sides of the conflict
      # (stage 2 "ours" and stage 3 "theirs") is written to temporary files whose
      # paths are yielded alongside the file path. The temporary files are deleted
      # automatically when the block returns.
      #
      # @example Inspect conflicting files
      #   repo.each_conflict do |file, your_version, their_version|
      #     puts "Conflict in #{file}"
      #     puts "Your version:"
      #     puts File.read(your_version)
      #     puts "Their version:"
      #     puts File.read(their_version)
      #   end
      #
      # @return [Array<String>] the list of unmerged file paths
      #
      # @raise [Git::FailedError] when `git diff --cached` exits outside the
      #   allowed range (exit code > 2)
      #
      # @yield [file, your_version, their_version] passes conflict details for
      #   each unmerged file
      #
      # @yieldparam file [String] path to the conflicting file, relative to the
      #   working tree
      #
      # @yieldparam your_version [String] path to a temporary file containing the
      #   stage-2 (ours) content for the conflicting file
      #
      # @yieldparam their_version [String] path to a temporary file containing the
      #   stage-3 (theirs) content for the conflicting file
      #
      # @yieldreturn [void]
      #
      def each_conflict
        Private.unmerged_paths(@execution_context).each do |file_path|
          Private.write_staged_file(@execution_context, file_path, 2) do |your_file|
            Private.write_staged_file(@execution_context, file_path, 3) do |their_file|
              yield(file_path, your_file.path, their_file.path)
            end
          end
        end
      end

      # Iterate over files with merge conflicts, yielding conflict details for each
      #
      # For each unmerged file, the staged content for both sides of the conflict
      # (stage 2 "ours" and stage 3 "theirs") is written to temporary files whose
      # paths are yielded alongside the file path. The temporary files are deleted
      # automatically when the block returns.
      #
      # @example Inspect conflicting files
      #   repo.conflicts do |file, your_version, their_version|
      #     puts "Conflict in #{file}"
      #     puts File.read(your_version)
      #     puts File.read(their_version)
      #   end
      #
      # @return [Array<String>] the list of unmerged file paths
      #
      # @raise [Git::FailedError] when `git diff --cached` exits outside the
      #   allowed range (exit code > 2)
      #
      # @yield [file, your_version, their_version] passes conflict details for
      #   each unmerged file
      #
      # @yieldparam file [String] path to the conflicting file, relative to the
      #   working tree
      #
      # @yieldparam your_version [String] path to a temporary file containing the
      #   stage-2 (ours) content for the conflicting file
      #
      # @yieldparam their_version [String] path to a temporary file containing the
      #   stage-3 (theirs) content for the conflicting file
      #
      # @yieldreturn [void]
      #
      # @deprecated Use {#each_conflict} instead
      #
      def conflicts(&)
        Git::Deprecation.warn(
          'Git::Repository#conflicts is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#each_conflict instead.'
        )
        each_conflict(&)
      end

      # Option keys accepted by {#revert}
      #
      # Derived from the 4.x option map for `Git::Lib#revert`.
      REVERT_ALLOWED_OPTS = %i[no_edit].freeze
      private_constant :REVERT_ALLOWED_OPTS

      # Revert one or more existing commits by creating new commits that undo
      # the changes those commits introduced
      #
      # The working tree must be clean before calling this method. By default
      # the editor is suppressed (`--no-edit`) so the commit message is taken
      # from git's default revert message without prompting.
      #
      # @example Revert the most recent commit
      #   repo.revert('HEAD')
      #
      # @example Revert a specific commit by SHA
      #   repo.revert('abc1234')
      #
      # @example Revert a range of commits
      #   repo.revert('HEAD~3..HEAD~1')
      #
      # @example Revert without suppressing the editor
      #   repo.revert('HEAD', no_edit: false)
      #
      # @param commitish [String, nil] the commit, ref, or rev range to revert;
      #   see `gitrevisions(7)` for accepted forms; defaults to `'HEAD'` when
      #   `nil`
      #
      # @param opts [Hash] additional options forwarded to `git revert`
      #
      # @option opts [Boolean, nil] :no_edit (true) suppress the commit-message
      #   editor (`--no-edit`); pass `false` to open the editor
      #
      # @return [String] git's stdout from the revert command
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def revert(commitish = nil, opts = {})
        commitish = 'HEAD' if commitish.nil?
        SharedPrivate.assert_valid_opts!(REVERT_ALLOWED_OPTS, **opts)
        opts = { no_edit: true }.merge(opts)
        Git::Commands::Revert::Start.new(@execution_context).call(commitish, **opts).stdout
      end

      # Private helpers local to {Git::Repository::Merging}
      #
      # @api private
      module Private
        # Tempfile name prefixes for staged content, keyed by git stage index
        STAGE_PREFIXES = { 2 => 'YOUR-', 3 => 'THEIR-' }.freeze

        module_function

        # Returns the list of file paths with unresolved merge conflicts
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #   used to run git commands
        #
        # @return [Array<String>] unmerged file paths
        #
        # @api private
        #
        def unmerged_paths(execution_context)
          result = Git::Commands::Diff.new(execution_context).call(cached: true)
          result.stdout.split("\n").filter_map do |line|
            ::Regexp.last_match(1) if line =~ /^\* Unmerged path (.*)/
          end
        end

        # Creates a Tempfile with the staged content for `file_path` at `stage`
        # and yields the open IO object to the block
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #   used to run git commands
        #
        # @param file_path [String] repository-relative path to the conflicting file
        #
        # @param stage [Integer] git stage index (2 = ours, 3 = theirs)
        #
        # @return [void]
        #
        # @yield [f] yields the open Tempfile containing the staged content
        #
        # @yieldparam f [Tempfile] open IO object for the staged content
        #
        # @yieldreturn [void]
        #
        # @api private
        #
        def write_staged_file(execution_context, file_path, stage)
          Tempfile.create([STAGE_PREFIXES[stage], File.basename(file_path)]) do |f|
            Git::Commands::Show.new(execution_context).call(":#{stage}:#{file_path}", out: f)
            f.flush
            yield f
          end
        end
      end
      private_constant :Private
    end
  end
end
