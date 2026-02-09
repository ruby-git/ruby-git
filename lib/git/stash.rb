# frozen_string_literal: true

module Git
  # A stash in a Git repository
  class Stash
    # Initialize a Stash object
    #
    # @param base [Git::Base] the git repository
    # @param message [String] the stash message
    # @param existing [Boolean] (false) if true, this is an existing stash (don't create)
    #
    def initialize(base, message, existing: false)
      @base = base
      @message = message
      save unless existing
    end

    def save
      @saved = @base.lib.stash_save(@message)
    end

    def saved?
      @saved
    end

    attr_reader :message

    def to_s
      message
    end
  end
end
