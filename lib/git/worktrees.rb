# frozen_string_literal: true

module Git
  # object that holds all the available worktrees
  class Worktrees
    include Enumerable

    def initialize(base)
      @worktrees = {}

      @base = base

      # Array contains [dir, git_hash]
      @base.lib.worktrees_all.each do |w|
        @worktrees[w[0]] = Git::Worktree.new(@base, w[0], w[1])
      end
    end

    # array like methods

    def size
      @worktrees.size
    end

    def each(&)
      @worktrees.values.each(&)
    end

    def [](worktree_name)
      @worktrees.values.each_with_object(@worktrees) do |worktree, worktrees|
        worktrees[worktree.full] ||= worktree
      end[worktree_name.to_s]
    end

    def to_s
      out = ''
      @worktrees.each_value do |b|
        out << b.to_s << "\n"
      end
      out
    end

    def prune
      @base.lib.worktree_prune
    end
  end
end
