# frozen_string_literal: true

module Git
  # Immutable value object for the status of one path in the index and working tree
  #
  # Each member holds one field of the entry `git status --porcelain=v2` reports
  # for the path. `index_status` and `worktree_status` are the `X` and `Y`
  # characters of that entry: `.` unmodified, `M` modified, `T` type changed, `A`
  # added, `D` deleted, `R` renamed, `C` copied, or `U` unmerged. Untracked
  # entries carry `?` in both and ignored entries carry `!` in both, mirroring
  # the `??` and `!!` codes of the short status format.
  #
  # The mode and SHA members are `nil` for untracked and ignored entries. For
  # unmerged entries the per-stage modes and SHAs live in `unmerged_stages` and
  # `mode_head`, `mode_index`, `sha_head`, and `sha_index` are `nil`.
  # `original_path` and `rename_score` are set only for rename and copy entries.
  #
  # The predicates follow these rules: `added?` when `index_status` is `A`,
  # `deleted?` when either status is `D`, `changed?` when either status is `M`
  # or `T`, `renamed?` when either status is `R`, `untracked?` and `ignored?`
  # from the `?` and `!` codes, and `unmerged?` when `unmerged_stages` is set.
  #
  # Every String member is a frozen copy of the value given, and
  # `unmerged_stages` is a deeply frozen copy, so an entry cannot be changed
  # through a member the caller still references.
  #
  # @example Inspect the status of one path
  #   file = repo.status_info['lib/foo.rb']
  #   file.index_status    #=> "M"
  #   file.worktree_status #=> "."
  #   file.changed?        #=> true
  #   file.sha_index       #=> "2bdf67abb163a4ffb2d7f3f0880c9fe5068ce782"
  #
  # @example Read the original path of a rename
  #   file = repo.status_info['lib/new_name.rb']
  #   file.renamed?      #=> true
  #   file.original_path #=> "lib/old_name.rb"
  #   file.rename_score  #=> 100
  #
  # @example Read the stages of a merge conflict
  #   file = repo.status_info['lib/conflict.rb']
  #   file.unmerged?             #=> true
  #   file.unmerged_stages[2]    #=> { mode: "100644", sha: "ba2906d0666c..." }
  #
  # @see Git::StatusInfo
  #
  # @see Git::Repository#status_info
  #
  # @see https://git-scm.com/docs/git-status#_porcelain_format_version_2
  #
  # @api public
  #
  # @!attribute [r] path
  #
  #   @return [String] the repository-relative path
  #
  # @!attribute [r] index_status
  #
  #   @return [String] the `X` status character (HEAD versus index), `?` for
  #     untracked and `!` for ignored entries
  #
  # @!attribute [r] worktree_status
  #
  #   @return [String] the `Y` status character (index versus working tree), `?`
  #     for untracked and `!` for ignored entries
  #
  # @!attribute [r] submodule
  #
  #   @return [String, nil] the four-character submodule state (`N...` for a
  #     regular file), or `nil` for untracked and ignored entries
  #
  # @!attribute [r] mode_head
  #
  #   @return [String, nil] the octal file mode in HEAD (`000000` when the path
  #     is not in HEAD), or `nil` for untracked, ignored, and unmerged entries
  #
  # @!attribute [r] mode_index
  #
  #   @return [String, nil] the octal file mode in the index (`000000` when the
  #     path is not in the index), or `nil` for untracked, ignored, and unmerged
  #     entries
  #
  # @!attribute [r] mode_worktree
  #
  #   @return [String, nil] the octal file mode in the working tree (`000000`
  #     when the path is not in the working tree), or `nil` for untracked and
  #     ignored entries
  #
  # @!attribute [r] sha_head
  #
  #   @return [String, nil] the object name of the blob in HEAD (all zeros when
  #     the path is not in HEAD), or `nil` for untracked, ignored, and unmerged
  #     entries
  #
  # @!attribute [r] sha_index
  #
  #   @return [String, nil] the object name of the blob in the index (all zeros
  #     when the path is not in the index), or `nil` for untracked, ignored, and
  #     unmerged entries
  #
  # @!attribute [r] original_path
  #
  #   @return [String, nil] the path the entry was renamed or copied from, or
  #     `nil` for every other entry
  #
  # @!attribute [r] rename_score
  #
  #   @return [Integer, nil] the similarity score of a rename or copy entry, or
  #     `nil` for every other entry
  #
  # @!attribute [r] unmerged_stages
  #
  #   @return [Hash{Integer => Hash{Symbol => String}}, nil] the mode and SHA of
  #     each conflict stage keyed by stage number (1 for the merge base, 2 for
  #     "ours", 3 for "theirs"), as frozen `\\{ mode:, sha: }` hashes, or `nil`
  #     for every other entry
  #
  StatusFileInfo = Data.define(
    :path,
    :index_status,
    :worktree_status,
    :submodule,
    :mode_head,
    :mode_index,
    :mode_worktree,
    :sha_head,
    :sha_index,
    :original_path,
    :rename_score,
    :unmerged_stages
  ) do
    # Creates a file status value object holding frozen copies of its members
    #
    # String members are duplicated and frozen, and `unmerged_stages` is
    # duplicated and frozen down to its mode and SHA strings, so neither this
    # value nor a {Git::StatusInfo} holding it can be changed through a member
    # the caller still references.
    #
    # @example Build an entry from parsed fields
    #   Git::StatusFileInfo.new(path: 'lib/foo.rb', index_status: 'M', worktree_status: '.', ...)
    #
    # @param members [Hash{Symbol => Object}] one value per member; every
    #   member is required
    #
    # @option members [String] :path the repository-relative path
    #
    # @option members [String] :index_status the `X` status character
    #
    # @option members [String] :worktree_status the `Y` status character
    #
    # @option members [String, nil] :submodule the four-character submodule state
    #
    # @option members [String, nil] :mode_head the octal file mode in HEAD
    #
    # @option members [String, nil] :mode_index the octal file mode in the index
    #
    # @option members [String, nil] :mode_worktree the octal file mode in the working tree
    #
    # @option members [String, nil] :sha_head the object name of the blob in HEAD
    #
    # @option members [String, nil] :sha_index the object name of the blob in the index
    #
    # @option members [String, nil] :original_path the path a rename or copy came from
    #
    # @option members [Integer, nil] :rename_score the similarity score of a rename or copy
    #
    # @option members [Hash{Integer => Hash{Symbol => String}}, nil] :unmerged_stages
    #   the mode and SHA of each conflict stage keyed by stage number
    #
    def initialize(**members)
      super(**members.transform_values { |value| deep_frozen(value) })
    end

    # Returns `true` when the path is not tracked by git
    #
    # @example Check an untracked path
    #   repo.status_info['new.rb'].untracked? #=> true
    #
    # @return [Boolean] `true` when both status characters are `?`
    #
    def untracked? = index_status == '?' && worktree_status == '?'

    # Returns `true` when the path is ignored
    #
    # Ignored entries are reported only when `git status` runs with `--ignored`.
    # {Git::Repository#status_info} does not pass that option, so this is
    # `false` for every entry it returns.
    #
    # @example Check an ignored entry
    #   file = Git::Parsers::Status.parse("! tmp/debug.log\0").first
    #   file.ignored? #=> true
    #
    # @return [Boolean] `true` when both status characters are `!`
    #
    def ignored? = index_status == '!' && worktree_status == '!'

    # Returns `true` when the path has merge conflicts
    #
    # @example Check a conflicted path
    #   repo.status_info['lib/conflict.rb'].unmerged? #=> true
    #
    # @return [Boolean] `true` when `unmerged_stages` is set
    #
    def unmerged? = !unmerged_stages.nil?

    # Returns `true` when the path was renamed in the index or working tree
    #
    # @example Check a renamed path
    #   repo.status_info['lib/new_name.rb'].renamed? #=> true
    #
    # @return [Boolean] `true` when either status character is `R`
    #
    def renamed? = index_status == 'R' || worktree_status == 'R'

    # Returns `true` when the path was added to the index and is not in HEAD
    #
    # @example Check a newly staged path
    #   repo.status_info['lib/new.rb'].added? #=> true
    #
    # @return [Boolean] `true` when `index_status` is `A`
    #
    def added? = index_status == 'A'

    # Returns `true` when the path was deleted from the index or working tree
    #
    # @example Check a deleted path
    #   repo.status_info['lib/old.rb'].deleted? #=> true
    #
    # @return [Boolean] `true` when either status character is `D`
    #
    def deleted? = index_status == 'D' || worktree_status == 'D'

    # Returns `true` when the path's content or type changed in the index or working tree
    #
    # @example Check a modified path
    #   repo.status_info['lib/foo.rb'].changed? #=> true
    #
    # @return [Boolean] `true` when either status character is `M` or `T`
    #
    def changed? = [index_status, worktree_status].intersect?(%w[M T])

    private

    # Returns a frozen copy of `value`, freezing the contents of a Hash recursively
    #
    # @param value [Object] a member value
    #
    # @return [Object] a frozen copy of a String or Hash; any other value as given
    #
    def deep_frozen(value)
      case value
      when String then value.dup.freeze
      when Hash then value.to_h { |key, item| [key, deep_frozen(item)] }.freeze
      else value
      end
    end
  end
end
