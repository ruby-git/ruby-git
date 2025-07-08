# frozen_string_literal: true

module Git
  # A stash in a Git repository
  class Stash
    def initialize(base, message, save: false)
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
