# frozen_string_literal: true

module Git
  # Represents a single stash entry in a Git repository
  #
  # @example Create a stash and inspect the result
  #   stash = Git::Stash.new(repo, 'WIP: feature work')
  #   stash.message  #=> "WIP: feature work"
  #   stash.saved?   #=> true
  #
  # @api public
  #
  class Stash
    # Initialize a Stash object
    #
    # When `existing` is `false` (the default), immediately calls {#save} to push
    # the current working-directory state onto the stash stack.
    #
    # @example Create a new stash entry
    #   stash = Git::Stash.new(repo, 'WIP: feature work')
    #   stash.saved?  #=> true
    #
    # @example Reference an existing stash without pushing
    #   stash = Git::Stash.new(repo, 'WIP: feature work', existing: true)
    #   stash.saved?  #=> nil
    #
    # @param base [Git::Repository] the git repository
    #
    # @param message [String] the stash message
    #
    # @param existing [Boolean] (false) when `true`, wraps an existing stash entry
    #   without pushing any changes
    #
    # @return [void]
    def initialize(base, message, existing: false)
      @base = base
      @message = message
      save unless existing
    end

    # Saves the current working-directory state to the stash stack
    #
    # @example Save changes to the stash stack
    #   stash = Git::Stash.new(repo, 'WIP', existing: true)
    #   stash.save  #=> true
    #
    # @return [Boolean] `true` if changes were stashed, `false` if there were no
    #   local changes to save
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def save
      @saved = stash_repository.stash_save(@message)
    end

    # Returns whether the stash was saved successfully
    #
    # @example Check if changes were stashed
    #   stash = Git::Stash.new(repo, 'WIP: feature work')
    #   stash.saved?  #=> true
    #
    # @return [Boolean, nil] `true` if changes were stashed, `false` if there were no
    #   local changes, `nil` if {#save} has not been called (e.g. `existing: true`)
    def saved?
      @saved
    end

    # Returns the stash description
    #
    # @example Read the stash message
    #   stash = Git::Stash.new(repo, 'WIP: feature work', existing: true)
    #   stash.message  #=> "WIP: feature work"
    #
    # @return [String] the stash message
    attr_reader :message

    # Returns the stash description as a string
    #
    # @example Convert stash to string
    #   stash = Git::Stash.new(repo, 'WIP: feature work', existing: true)
    #   stash.to_s  #=> "WIP: feature work"
    #
    # @return [String] the stash message
    def to_s
      message
    end

    private

    # @return [Git::Repository]
    #
    def stash_repository
      @base
    end
  end
end
