# frozen_string_literal: true

module Git
  class Repository
    # Internal helpers shared by `Git::Repository::*` topic modules
    #
    # Methods defined here use `module_function` so they are callable as
    # `SharedPrivate.foo(...)` from any topic module within `Git::Repository`
    # without being added to `Git::Repository`'s instance namespace via `include`.
    #
    # The constant is declared `private_constant` so it is inaccessible from
    # outside the `Git::Repository` class body; callers inside topic modules use
    # the short unqualified form `SharedPrivate.foo(...)`.
    #
    # @api private
    #
    module SharedPrivate
      module_function

      # Validate that candidate option keys are listed in `allowed`
      #
      # Used by facade methods to enforce that only documented options (those
      # named in `@option` tags) are accepted, even when the underlying command
      # class would accept more keys. This prevents silent expansion of the
      # facade's public contract.
      #
      # @example Reject an undocumented option
      #   ADD_ALLOWED_OPTS = %i[all force].freeze
      #
      #   SharedPrivate.assert_valid_opts!(ADD_ALLOWED_OPTS, bogus: true)
      #   #=> raises ArgumentError: Unknown options: bogus
      #
      # @param allowed [Array<Symbol>] the keys permitted by the facade method
      #
      # @param candidate_keywords [Hash<Symbol, Object>] the keywords to validate
      #
      # @option candidate_keywords [Object] key_name a candidate keyword value
      #
      # @return [void]
      #
      # @raise [ArgumentError] when any candidate key is not in `allowed`
      #
      def assert_valid_opts!(allowed, **candidate_keywords)
        unknown = candidate_keywords.keys - allowed
        return if unknown.empty?

        raise ArgumentError, "Unknown options: #{unknown.join(', ')}"
      end

      # Raise unless `branch` names an existing local branch
      #
      # Used by facade methods that check out a branch, do work on it, and switch
      # back. {Git::Repository#checkout} also accepts commit SHAs, tags, and
      # remote-tracking branches, all of which detach HEAD; work committed there
      # would be left dangling once the original branch is restored, and git has
      # no way to report that.
      #
      # @example With an existing local branch
      #   SharedPrivate.assert_local_branch!(repo, 'feature') #=> nil
      #
      # @example With a tag
      #   SharedPrivate.assert_local_branch!(repo, 'v1.0.0')
      #   #=> raises ArgumentError: 'v1.0.0' is not an existing local branch
      #
      # @param repository [Git::Repository] the repository to check
      #
      # @param branch [String] the branch name to verify
      #
      # @return [void]
      #
      # @raise [ArgumentError] when `branch` is not an existing local branch
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def assert_local_branch!(repository, branch)
        return if repository.local_branch?(branch)

        raise ArgumentError, "'#{branch}' is not an existing local branch"
      end

      # Returns a revision that restores the current HEAD after switching branches
      #
      # Used by facade methods that temporarily check out another branch and
      # then switch back. On a branch, the branch name is enough. When HEAD is
      # detached, {Git::Repository#current_branch} reports `'HEAD'`, which after
      # a checkout resolves to the new branch rather than the original commit,
      # so the commit SHA is captured instead. An unborn branch (one with no
      # commits yet) has no ref to check out by name, so it is rejected here,
      # before the caller switches away from it.
      #
      # @example On a branch
      #   SharedPrivate.head_restore_point(repo) #=> "main"
      #
      # @example With a detached HEAD
      #   SharedPrivate.head_restore_point(repo) #=> "9b9b31e704c0b85ffdd8d2af2ded85170a5af87d"
      #
      # @param repository [Git::Repository] the repository whose HEAD to record
      #
      # @return [String] the current branch name, or the full HEAD commit SHA
      #   when HEAD is detached
      #
      # @raise [Git::Error] when HEAD is on an unborn branch
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def head_restore_point(repository)
        head = repository.current_branch_state
        case head.state
        when :detached then repository.rev_parse('HEAD').strip
        when :unborn
          raise Git::Error, "HEAD is on the unborn branch '#{head.name}', which cannot be restored " \
                            'after switching branches; make a commit on it first'
        else head.name
        end
      end
    end

    private_constant :SharedPrivate
  end
end
