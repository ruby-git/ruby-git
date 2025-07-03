# frozen_string_literal: true

require 'git/path'

module Git
  class Worktree < Path
    attr_accessor :full, :dir

    def initialize(base, dir, gcommit = nil)
      @full = dir
      @full += " #{gcommit}" unless gcommit.nil?
      @base = base
      @dir = dir
      @gcommit = gcommit
    end

    def gcommit
      @gcommit ||= @base.gcommit(@full)
      @gcommit
    end

    def add
      @base.lib.worktree_add(@dir, @gcommit)
    end

    def remove
      @base.lib.worktree_remove(@dir)
    end

    def to_a
      [@full]
    end

    def to_s
      @full
    end
  end
end
