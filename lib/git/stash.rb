# frozen_string_literal: true

module Git
  # A stash in a Git repository
  class Stash
    def initialize(base, message, existing = nil, save: nil)
      Git::Deprecation.warn('The "existing" argument is deprecated and will be removed in a future version. Use "save:" instead.') unless existing.nil?

      # default is false
      save = existing.nil? && save.nil? ? false : save | existing

      @base = base
      @message = message
      self.save unless save
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
