# frozen_string_literal: true

require 'git/commands/stash'
require 'git/parsers/stash'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for stash operations
    #
    # Each method maps onto a `git stash` subcommand. Methods that identify or
    # create a stash entry ({#stash_infos}, {#stash_push}, {#stash_store}) return
    # {Git::StashInfo} values; methods that only change or display the stash
    # return git's stdout. Every method that takes a stash ({#stash_apply},
    # {#stash_pop}, {#stash_drop}, {#stash_show}, {#stash_branch}) accepts a
    # {Git::StashInfo}, a `stash@{N}` name, an Integer index (`0` is the most
    # recent entry), or `nil` for the most recent entry. Methods that take
    # options accept them as a trailing positional Hash, so
    # `repo.stash_apply(index: true)` and `repo.stash_apply(nil, opts)` with a
    # stored `opts` Hash both work.
    #
    # {#stashes_all}, {#stash_save}, and {#stash_list} are the legacy surface.
    # They are deprecated and will be removed in v6.0.0.
    #
    # Included by {Git::Repository}.
    #
    # @api private
    #
    module Stashing
      # Returns every stash entry as a {Git::StashInfo}, newest first
      #
      # The order and indices match `git stash list`: the first element is
      # `stash@{0}`, the most recent entry.
      #
      # @example List stash entries (newest first)
      #   repo.stash_infos.map(&:name) #=> ["stash@{0}", "stash@{1}"]
      #
      # @example Apply the oldest entry
      #   repo.stash_apply(repo.stash_infos.last)
      #
      # @return [Array<Git::StashInfo>] the stash entries, newest first; empty
      #   when there are none
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_infos
        result = Git::Commands::Stash::List.new(@execution_context).call
        Git::Parsers::Stash.parse_list(result.stdout)
      end

      # Option keys accepted by {#stash_push}
      STASH_PUSH_ALLOWED_OPTS = %i[
        patch p staged S keep_index k no_keep_index quiet q include_untracked u all a
        message m pathspec_from_file pathspec_file_nul
      ].freeze
      private_constant :STASH_PUSH_ALLOWED_OPTS

      # Save the working tree and index state to a new stash entry
      #
      # The stash list is read before and after the push and the entry counts are
      # compared, so the return value is `nil` whenever git created no entry. This
      # holds with `quiet: true`, which suppresses git's "No local changes to
      # save" message.
      #
      # @overload stash_push(*pathspec, options = {})
      #
      #   @example Stash all changes with a message
      #     info = repo.stash_push(message: 'WIP: feature work')
      #     info.name    #=> "stash@{0}"
      #     info.message #=> "On main: WIP: feature work"
      #
      #   @example Stash only specific paths
      #     repo.stash_push('src/a.rb', 'src/b.rb', message: 'partial work')
      #
      #   @example Nothing to stash
      #     repo.stash_push #=> nil
      #
      #   @param pathspec [Array<String>] paths that limit what gets stashed; when
      #     empty, all changes are stashed
      #
      #   @param options [Hash] options for the push
      #
      #   @option options [Boolean, nil] :patch (nil) interactively select hunks to
      #     stash (alias: `:p`)
      #
      #   @option options [Boolean, nil] :p (nil) alias for `:patch`
      #
      #   @option options [Boolean, nil] :staged (nil) stash only the staged changes
      #     (alias: `:S`; requires git 2.35+)
      #
      #   @option options [Boolean, nil] :S (nil) alias for `:staged` (requires git
      #     2.35+)
      #
      #   @option options [Boolean, nil] :keep_index (nil) keep the staged changes
      #     in the index (alias: `:k`)
      #
      #   @option options [Boolean, nil] :k (nil) alias for `:keep_index`
      #
      #   @option options [Boolean, nil] :no_keep_index (nil) do not keep the staged
      #     changes in the index
      #
      #   @option options [Boolean, nil] :quiet (nil) suppress informational
      #     messages (alias: `:q`)
      #
      #   @option options [Boolean, nil] :q (nil) alias for `:quiet`
      #
      #   @option options [Boolean, nil] :include_untracked (nil) include untracked
      #     files in the stash (alias: `:u`)
      #
      #   @option options [Boolean, nil] :u (nil) alias for `:include_untracked`
      #
      #   @option options [Boolean, nil] :all (nil) include untracked and ignored
      #     files in the stash (alias: `:a`)
      #
      #   @option options [Boolean, nil] :a (nil) alias for `:all`
      #
      #   @option options [String] :message (nil) the stash message (alias: `:m`)
      #
      #   @option options [String] :m (nil) alias for `:message`
      #
      #   @option options [String] :pathspec_from_file (nil) read pathspecs from the
      #     given file; pass `-` to read from standard input
      #
      #   @option options [Boolean, nil] :pathspec_file_nul (nil) when used with
      #     `:pathspec_from_file`, pathspecs are NUL-separated
      #
      #   @return [Git::StashInfo, nil] the new entry, or `nil` when there were no
      #     local changes to save
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_push(*pathspec)
        pathspec, opts = Private.split_pathspec_and_opts(pathspec)
        SharedPrivate.assert_valid_opts!(STASH_PUSH_ALLOWED_OPTS, **opts)
        previous_count = stash_infos.size
        Git::Commands::Stash::Push.new(@execution_context).call(*pathspec, **opts)
        entries = stash_infos
        entries.first if entries.size > previous_count
      end

      # Option keys accepted by {#stash_apply}
      STASH_APPLY_ALLOWED_OPTS = %i[index quiet q].freeze
      private_constant :STASH_APPLY_ALLOWED_OPTS

      # Apply a stash entry to the working tree, keeping it in the stash list
      #
      # @example Apply the most recent entry
      #   repo.stash_apply #=> "On branch main\nChanges not staged for commit:..."
      #
      # @example Apply an entry from {#stash_infos}
      #   repo.stash_apply(repo.stash_infos.last)
      #
      # @example Apply an entry by name and restore the index too
      #   repo.stash_apply('stash@{1}', index: true)
      #
      # @param stash [Git::StashInfo, String, Integer, nil] the entry to apply: a
      #   {Git::StashInfo}, a `stash@{N}` name, an Integer `N` (`0` is the most
      #   recent entry), or `nil` for the most recent entry
      #
      # @param opts [Hash] options for the apply
      #
      # @option opts [Boolean, nil] :index (nil) restore the index state as
      #   well as the working tree
      #
      # @option opts [Boolean, nil] :quiet (nil) suppress informational
      #   messages (alias: `:q`)
      #
      # @option opts [Boolean, nil] :q (nil) alias for `:quiet`
      #
      # @return [String] git's stdout from the apply
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_apply(stash = nil, opts = {})
        stash, opts = Private.split_stash_and_opts(stash, opts)
        SharedPrivate.assert_valid_opts!(STASH_APPLY_ALLOWED_OPTS, **opts)
        Git::Commands::Stash::Apply.new(@execution_context).call(stash, **opts).stdout
      end

      # Option keys accepted by {#stash_pop}
      STASH_POP_ALLOWED_OPTS = %i[index quiet q].freeze
      private_constant :STASH_POP_ALLOWED_OPTS

      # Apply a stash entry to the working tree and remove it from the stash list
      #
      # @example Pop the most recent entry
      #   repo.stash_pop #=> "On branch main\n...Dropped refs/stash@{0} (abc1234...)"
      #
      # @example Pop an entry from {#stash_infos}
      #   repo.stash_pop(repo.stash_infos.last)
      #
      # @param stash [Git::StashInfo, String, Integer, nil] the entry to pop: a
      #   {Git::StashInfo}, a `stash@{N}` name, an Integer `N` (`0` is the most
      #   recent entry), or `nil` for the most recent entry
      #
      # @param opts [Hash] options for the pop
      #
      # @option opts [Boolean, nil] :index (nil) restore the index state as
      #   well as the working tree
      #
      # @option opts [Boolean, nil] :quiet (nil) suppress informational
      #   messages (alias: `:q`)
      #
      # @option opts [Boolean, nil] :q (nil) alias for `:quiet`
      #
      # @return [String] git's stdout from the pop
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_pop(stash = nil, opts = {})
        stash, opts = Private.split_stash_and_opts(stash, opts)
        SharedPrivate.assert_valid_opts!(STASH_POP_ALLOWED_OPTS, **opts)
        Git::Commands::Stash::Pop.new(@execution_context).call(stash, **opts).stdout
      end

      # Option keys accepted by {#stash_drop}
      STASH_DROP_ALLOWED_OPTS = %i[quiet q].freeze
      private_constant :STASH_DROP_ALLOWED_OPTS

      # Remove a single stash entry from the stash list
      #
      # @example Drop the most recent entry
      #   repo.stash_drop #=> "Dropped refs/stash@{0} (abc1234...)"
      #
      # @example Drop an entry from {#stash_infos}
      #   repo.stash_drop(repo.stash_infos.last)
      #
      # @param stash [Git::StashInfo, String, Integer, nil] the entry to drop: a
      #   {Git::StashInfo}, a `stash@{N}` name, an Integer `N` (`0` is the most
      #   recent entry), or `nil` for the most recent entry
      #
      # @param opts [Hash] options for the drop
      #
      # @option opts [Boolean, nil] :quiet (nil) suppress informational
      #   messages (alias: `:q`)
      #
      # @option opts [Boolean, nil] :q (nil) alias for `:quiet`
      #
      # @return [String] git's stdout from the drop
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_drop(stash = nil, opts = {})
        stash, opts = Private.split_stash_and_opts(stash, opts)
        SharedPrivate.assert_valid_opts!(STASH_DROP_ALLOWED_OPTS, **opts)
        Git::Commands::Stash::Drop.new(@execution_context).call(stash, **opts).stdout
      end

      # Option keys accepted by {#stash_show}
      STASH_SHOW_ALLOWED_OPTS = %i[
        patch numstat raw shortstat unified U include_untracked u no_include_untracked
        only_untracked find_renames M find_copies C find_copies_harder inter_hunk_context dirstat
      ].freeze
      private_constant :STASH_SHOW_ALLOWED_OPTS

      # Show the changes recorded in a stash entry as a diff
      #
      # Without options, git prints a diffstat. The output is returned as git
      # prints it.
      #
      # @example Show the diffstat of the most recent entry
      #   repo.stash_show #=> " file.txt | 2 +-\n 1 file changed, 1 insertion(+), 1 deletion(-)"
      #
      # @example Show the full patch of an entry from {#stash_infos}
      #   repo.stash_show(repo.stash_infos.last, patch: true)
      #
      # @param stash [Git::StashInfo, String, Integer, nil] the entry to show: a
      #   {Git::StashInfo}, a `stash@{N}` name, an Integer `N` (`0` is the most
      #   recent entry), or `nil` for the most recent entry
      #
      # @param opts [Hash] options for the show
      #
      # @option opts [Boolean, nil] :patch (nil) show the diff as a patch
      #
      # @option opts [Boolean, nil] :numstat (nil) show per-file insertion and
      #   deletion counts
      #
      # @option opts [Boolean, nil] :raw (nil) show per-file mode, object id,
      #   and status metadata
      #
      # @option opts [Boolean, nil] :shortstat (nil) show only the summary line
      #
      # @option opts [Integer, String] :unified (nil) number of context lines
      #   in the patch (alias: `:U`)
      #
      # @option opts [Integer, String] :U (nil) alias for `:unified`
      #
      # @option opts [Boolean, nil] :include_untracked (nil) include the
      #   untracked files recorded in the entry (alias: `:u`; requires git 2.30+)
      #
      # @option opts [Boolean, nil] :u (nil) alias for `:include_untracked`
      #   (requires git 2.30+)
      #
      # @option opts [Boolean, nil] :no_include_untracked (nil) exclude the
      #   untracked files recorded in the entry (requires git 2.30+)
      #
      # @option opts [Boolean, nil] :only_untracked (nil) show only the
      #   untracked files recorded in the entry (requires git 2.30+)
      #
      # @option opts [Boolean, Integer, nil] :find_renames (nil) detect
      #   renames, optionally with a similarity threshold (alias: `:M`)
      #
      # @option opts [Boolean, Integer, nil] :M (nil) alias for `:find_renames`
      #
      # @option opts [Boolean, Integer, nil] :find_copies (nil) detect copies
      #   as well as renames, optionally with a similarity threshold (alias: `:C`)
      #
      # @option opts [Boolean, Integer, nil] :C (nil) alias for `:find_copies`
      #
      # @option opts [Boolean, nil] :find_copies_harder (nil) inspect unmodified
      #   files as copy sources
      #
      # @option opts [Integer, String] :inter_hunk_context (nil) number of
      #   context lines between hunks before they are merged
      #
      # @option opts [Boolean, String, nil] :dirstat (nil) include directory
      #   statistics, optionally with parameters
      #
      # @return [String] git's stdout from the show
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_show(stash = nil, opts = {})
        stash, opts = Private.split_stash_and_opts(stash, opts)
        SharedPrivate.assert_valid_opts!(STASH_SHOW_ALLOWED_OPTS, **opts)
        Git::Commands::Stash::Show.new(@execution_context).call(stash, **opts).stdout
      end

      # Create and check out a branch from the commit a stash entry was based on
      #
      # Applies the entry on the new branch and, when that succeeds, drops the
      # entry from the stash list.
      #
      # @example Branch from the most recent entry
      #   repo.stash_branch('feature') #=> "Switched to a new branch 'feature'\n..."
      #
      # @example Branch from an entry from {#stash_infos}
      #   repo.stash_branch('feature', repo.stash_infos.last)
      #
      # @param branch_name [String] the name of the branch to create
      #
      # @param stash [Git::StashInfo, String, Integer, nil] the entry to branch
      #   from: a {Git::StashInfo}, a `stash@{N}` name, an Integer `N` (`0` is the
      #   most recent entry), or `nil` for the most recent entry
      #
      # @return [String] git's stdout from the branch command
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_branch(branch_name, stash = nil)
        Git::Commands::Stash::Branch.new(@execution_context).call(branch_name, stash).stdout
      end

      # Create a stash commit without adding it to the stash list
      #
      # The working tree and index are left unchanged. Pass the returned object
      # id to {#stash_store} to add it to the stash list later.
      #
      # @example Create a stash commit
      #   repo.stash_create('WIP') #=> "3f8b2d9c..." (the full object id)
      #
      # @example Nothing to stash
      #   repo.stash_create #=> nil
      #
      # @param message [String, nil] the message for the stash commit; `nil` for
      #   git's default message
      #
      # @return [String, nil] the object id of the stash commit, or `nil` when
      #   there were no local changes
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_create(message = nil)
        oid = Git::Commands::Stash::Create.new(@execution_context).call(message).stdout.strip
        oid.empty? ? nil : oid
      end

      # Option keys accepted by {#stash_store}
      STASH_STORE_ALLOWED_OPTS = %i[message m quiet q].freeze
      private_constant :STASH_STORE_ALLOWED_OPTS

      # Add a stash commit created by {#stash_create} to the stash list
      #
      # The stash list is read after the store to return the new top entry.
      #
      # @example Store a stash commit
      #   oid = repo.stash_create
      #   info = repo.stash_store(oid, message: 'saved for later')
      #   info.name    #=> "stash@{0}"
      #   info.message #=> "saved for later"
      #
      # @param commit [String] the object id of the stash commit to store
      #
      # @param opts [Hash] options for the store
      #
      # @option opts [String] :message (nil) the message for the stash entry
      #   (alias: `:m`)
      #
      # @option opts [String] :m (nil) alias for `:message`
      #
      # @option opts [Boolean, nil] :quiet (nil) suppress informational
      #   messages (alias: `:q`)
      #
      # @option opts [Boolean, nil] :q (nil) alias for `:quiet`
      #
      # @return [Git::StashInfo] the stored entry, now at the top of the stash list
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_store(commit, opts = {})
        SharedPrivate.assert_valid_opts!(STASH_STORE_ALLOWED_OPTS, **opts)
        Git::Commands::Stash::Store.new(@execution_context).call(commit, **opts)
        stash_infos.first
      end

      # Remove all stash entries
      #
      # Removes all entries from the stash list. Use with caution as this
      # operation cannot be undone.
      #
      # @example Clear all stashes
      #   repo.stash_clear #=> ""
      #
      # @return [String] the output from the git stash clear command
      #   (typically empty)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_clear
        Git::Commands::Stash::Clear.new(@execution_context).call.stdout
      end

      # Returns all stash entries as an array of index and message pairs
      #
      # Lists all stash entries in the repository ordered from oldest to newest.
      # The index is a sequential number starting from 0 for the oldest stash. The
      # message is the stash description with the leading branch prefix (e.g.
      # `"On main:"` or `"WIP on main:"`) stripped.
      #
      # @example List all stashes (oldest first)
      #   repo.stashes_all #=> [[0, "Fix bug"], [1, "Add feature"]]
      #
      # @return [Array<Array(Integer, String)>] array of `[index, message]` pairs
      #   where index is the sequential position (0 is oldest) and message is the
      #   stash description with the branch prefix stripped
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @note The sequential index returned here is **not** the same as git's
      #   `stash@{N}` reference used by {#stash_apply}. In git, `stash@{0}` is the
      #   **most recent** stash, while index `0` here is the **oldest**. To apply a
      #   specific stash from this list, convert the entry's position to a git
      #   reference: `'stash@{%d}' % (total - 1 - index)`, or pass the string
      #   reference directly to {#stash_apply}.
      #
      # @deprecated Use {#stash_infos} instead. It returns {Git::StashInfo} entries
      #   newest first with git's own `stash@{N}` indices and the full message.
      #   This method will be removed in v6.0.0.
      #
      # @see #stash_infos
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stashes_all
        Git::Deprecation.warn(
          'Git::Repository#stashes_all is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#stash_infos instead.'
        )
        stash_infos.reverse.each_with_index.map do |info, i|
          message = info.message.sub(/^(?:WIP on|On)\s+[^:]+:\s*/, '')
          [i, message]
        end
      end

      # Returns stash entries as a formatted string matching `git stash list` output
      #
      # @example List stashes as a formatted string
      #   repo.stash_list #=> "stash@{0}: On main: WIP\nstash@{1}: On feature: Fix bug"
      #
      # @return [String] newline-joined `"stash@{n}: <full message>"` entries, or an
      #   empty string when there are no stashes; the format matches `git stash list`
      #   output
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @deprecated Use {#stash_infos} instead and format the entries yourself:
      #   `repo.stash_infos.map { |s| "#{s.name}: #{s.message}" }.join("\n")`.
      #   This method will be removed in v6.0.0, and a later release will reuse
      #   the name for a method returning `Array<Git::StashInfo>`.
      #
      # @see #stash_infos
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_list
        Git::Deprecation.warn(
          'Git::Repository#stash_list is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#stash_infos instead.'
        )
        stash_infos.map { |info| "#{info.name}: #{info.message}" }.join("\n")
      end

      # Save the current working directory and index state to a new stash
      #
      # @example Save current changes
      #   repo.stash_save('WIP: feature work') #=> true
      #
      # @param message [String] the stash message
      #
      # @return [Boolean] true if changes were stashed, false if there were no
      #   local changes to save
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @deprecated Use {#stash_push} with the `:message` option instead. It
      #   returns the new {Git::StashInfo}, or `nil` when there were no local
      #   changes to save. This method will be removed in v6.0.0.
      #
      # @see #stash_push
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_save(message) # rubocop:disable Naming/PredicateMethod
        Git::Deprecation.warn(
          'Git::Repository#stash_save is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#stash_push(message: ...) instead.'
        )
        result = Git::Commands::Stash::Push.new(@execution_context).call(message: message)
        !result.stdout.include?('No local changes to save')
      end

      # Private helpers local to {Git::Repository::Stashing}
      #
      # @api private
      #
      module Private
        module_function

        # Separate the stash operand from a positional options Hash
        #
        # The stash-taking facade methods are declared `(stash = nil, opts = {})`.
        # When the caller omits the stash and passes only options
        # (`repo.stash_apply(index: true)`), Ruby binds the Hash to `stash`; this
        # moves it to `opts` so both call shapes reach the command the same way.
        #
        # @example Options passed without a stash
        #   Private.split_stash_and_opts({ index: true }, {}) #=> [nil, { index: true }]
        #
        # @example A stash and options
        #   Private.split_stash_and_opts('stash@{1}', { index: true }) #=> ["stash@{1}", { index: true }]
        #
        # @param stash [Git::StashInfo, String, Integer, Hash, nil] the stash
        #   operand, or the options Hash when the stash was omitted
        #
        # @param trailing [Hash] the second positional argument as bound by Ruby
        #
        # @return [Array(Object, Hash)] the stash operand and the options Hash
        #
        def split_stash_and_opts(stash, trailing)
          return [nil, stash] if stash.is_a?(Hash) && trailing.empty?

          [stash, trailing]
        end

        # Separate a trailing options Hash from a pathspec list
        #
        # {Git::Repository::Stashing#stash_push} takes a variadic pathspec, so
        # its options arrive as the last positional argument when present.
        #
        # @example Pathspecs followed by options
        #   Private.split_pathspec_and_opts(['a.rb', { message: 'WIP' }])
        #   #=> [["a.rb"], { message: "WIP" }]
        #
        # @example Pathspecs only
        #   Private.split_pathspec_and_opts(['a.rb']) #=> [["a.rb"], {}]
        #
        # @param pathspec [Array<String, Hash>] the positional arguments, possibly
        #   ending in an options Hash
        #
        # @return [Array(Array<String>, Hash)] the pathspecs and the options Hash
        #
        def split_pathspec_and_opts(pathspec)
          return [pathspec[0...-1], pathspec.last] if pathspec.last.is_a?(Hash)

          [pathspec, {}]
        end
      end
      private_constant :Private
    end
  end
end
