# frozen_string_literal: true

require 'git/commands/config_option_syntax'
require 'git/commands/fetch'
require 'git/commands/ls_remote'
require 'git/commands/pull'
require 'git/commands/push'
require 'git/commands/remote'
require 'git/parsers/ls_remote'
require 'git/remote'

require 'git/repository/shared_private'

module Git
  class Repository
    # Mixin that adds remote operation facade methods to {Git::Repository}
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module RemoteOperations # rubocop:disable Metrics/ModuleLength
      # Key normalizations for {#fetch} options
      #
      # Maps dash-style option keys (which the 4.x `Git::Lib#fetch` accepted)
      # to their canonical underscore-style equivalents.
      #
      # @return [Hash{Symbol => Symbol}]
      #
      # @api private
      #
      FETCH_KEY_NORMALIZATIONS = { 'update-head-ok': :update_head_ok, 'prune-tags': :prune_tags }.freeze
      private_constant :FETCH_KEY_NORMALIZATIONS

      # Option keys accepted by {#fetch}
      #
      # Derived from the 4.x `FETCH_OPTION_MAP` in `Git::Lib`.
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      FETCH_ALLOWED_OPTS = %i[all tags t prune p prune_tags P force f update_head_ok u unshallow depth ref].freeze
      private_constant :FETCH_ALLOWED_OPTS

      # Download objects and refs from a remote repository
      #
      # Fetches branches and/or tags from one or more other repositories, along
      # with the objects necessary to complete their histories. The local
      # tracking references are updated but the working directory is not
      # modified.
      #
      # @example Fetch from the default remote
      #   repo.fetch
      #
      # @example Fetch from a named remote
      #   repo.fetch('upstream')
      #
      # @example Fetch all remotes at once
      #   repo.fetch(all: true)
      #
      # @example Fetch and prune deleted remote branches
      #   repo.fetch('origin', prune: true)
      #
      # @example Fetch a specific refspec
      #   repo.fetch('origin', ref: 'refs/heads/main:refs/remotes/origin/main')
      #
      # @example Fetch multiple refspecs
      #   repo.fetch('origin', ref: ['refs/heads/main', 'refs/heads/develop'])
      #
      # @example Fetch and include all tags
      #   repo.fetch('origin', tags: true)
      #
      # @overload fetch(remote = 'origin', opts = {})
      #
      #   @param remote [String, Hash, nil] the remote name or URL to fetch from
      #
      #     When a Hash is given it is treated as `opts` and `remote` defaults to
      #     `nil` (which omits the remote positional argument and lets git use the
      #     configured default).
      #
      #   @param opts [Hash] options for the fetch command
      #
      #   @option opts [Boolean, nil] :all (nil) fetch from all configured remotes
      #     (`--all`)
      #
      #   @option opts [Boolean, nil] :tags (nil) fetch all tags from the remote
      #     (`--tags`)
      #
      #     Alias: `:t`
      #
      #   @option opts [Boolean, nil] :prune (nil) remove remote-tracking references
      #     that no longer exist on the remote (`--prune`)
      #
      #     Alias: `:p`
      #
      #   @option opts [Boolean, nil] :prune_tags (nil) remove local tags that no
      #     longer exist on the remote (`--prune-tags`)
      #
      #     Alias: `:P`. The legacy dash-style key `:'prune-tags'` is also accepted
      #     and normalized automatically.
      #
      #   @option opts [Boolean, nil] :force (nil) override the fast-forward check
      #     when using explicit refspecs (`--force`)
      #
      #     Alias: `:f`
      #
      #   @option opts [Boolean, nil] :update_head_ok (nil) allow `git fetch` to
      #     update the branch pointed to by `HEAD` (`--update-head-ok`)
      #
      #     Alias: `:u`. The legacy dash-style key `:'update-head-ok'` is also
      #     accepted and normalized automatically.
      #
      #   @option opts [Boolean, nil] :unshallow (nil) convert a shallow clone into a
      #     full repository (`--unshallow`)
      #
      #   @option opts [String, Integer] :depth (nil) limit history to N commits
      #     from each branch tip (`--depth=N`)
      #
      #   @option opts [String, Array<String>] :ref (nil) one or more refspecs to
      #     fetch; forwarded as positional arguments after the remote name. An
      #     explicit `remote` is required when `:ref` is given.
      #
      #   @return [String] the merged stdout from the fetch command
      #
      #   @raise [ArgumentError] when unsupported option keys are provided or `:ref`
      #     is supplied without an explicit remote
      #
      #   @raise [Git::FailedError] when git exits with a non-zero status
      #
      def fetch(remote = 'origin', opts = {})
        remote, opts = Private.resolve_fetch_target(remote, opts)

        opts = Private.normalize_fetch_keys(opts)
        SharedPrivate.assert_valid_opts!(FETCH_ALLOWED_OPTS, **opts)

        opts = opts.dup
        refspecs = Array(opts.delete(:ref)).compact
        positionals = [*([remote] if remote), *refspecs]

        Git::Commands::Fetch.new(@execution_context).call(*positionals, **opts, merge: true).stdout
      end

      # Option keys accepted by {#pull}
      #
      # Derived from the 4.x `PULL_OPTION_MAP` in `Git::Lib`.
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      PULL_ALLOWED_OPTS = %i[allow_unrelated_histories].freeze
      private_constant :PULL_ALLOWED_OPTS

      # Incorporate changes from a remote repository into the current branch
      #
      # Fetches from the given remote and merges into the current branch. In its
      # default mode, `git pull` is shorthand for `git fetch` followed by
      # `git merge FETCH_HEAD`. The merge editor is suppressed (`--no-edit`) and
      # progress output is silenced (`--no-progress`) by default.
      #
      # @example Pull from the default remote and branch
      #   repo.pull
      #
      # @example Pull from a named remote
      #   repo.pull('upstream')
      #
      # @example Pull a specific branch from a remote
      #   repo.pull('origin', 'main')
      #
      # @example Pull allowing unrelated histories
      #   repo.pull('origin', 'main', allow_unrelated_histories: true)
      #
      # @overload pull(remote = nil, branch = nil, opts = {})
      #
      #   @param remote [String, nil] the remote name or URL to pull from
      #
      #     When nil, git uses the tracking remote for the current branch.
      #
      #   @param branch [String, nil] the remote branch name to pull
      #
      #     When nil, git uses the tracking branch for the current branch.
      #     A branch may not be specified without also specifying a remote.
      #
      #   @param opts [Hash] options for the pull command
      #
      #   @option opts [Boolean, nil] :allow_unrelated_histories (nil) allow merging
      #     histories that do not share a common ancestor
      #     (`--allow-unrelated-histories`)
      #
      #   @return [String] the stdout from the pull command
      #
      #   @raise [ArgumentError] when a branch is given without a remote, or when
      #     unsupported option keys are provided
      #
      #   @raise [Git::FailedError] when git exits with a non-zero status
      #
      def pull(remote = nil, branch = nil, opts = {})
        raise ArgumentError, 'You must specify a remote if a branch is specified' if remote.nil? && !branch.nil?

        SharedPrivate.assert_valid_opts!(PULL_ALLOWED_OPTS, **opts)
        positional_args = [remote, branch].compact
        Git::Commands::Pull
          .new(@execution_context)
          .call(*positional_args, no_edit: true, no_progress: true, **opts)
          .stdout
      end

      # Option keys accepted by {#push}
      #
      # Derived from the 4.x `PUSH_OPTION_MAP` in `Git::Lib`.
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      PUSH_ALLOWED_OPTS = %i[mirror delete force f push_option all tags].freeze
      private_constant :PUSH_ALLOWED_OPTS

      # Push refs to a remote repository
      #
      # @example Push using the current branch's default remote and push configuration
      #   repo.push
      #
      # @example Push to a named remote
      #   repo.push('origin')
      #
      # @example Force-push the current branch to a named remote
      #   repo.push('origin', force: true)
      #
      # @example Push a specific branch to a named remote
      #   repo.push('origin', 'main')
      #
      # @example Push a branch and all tags to a named remote
      #   repo.push('origin', 'main', tags: true)
      #
      # @example Push all branches to a named remote
      #   repo.push('origin', all: true)
      #
      # @example Mirror all refs to a named remote
      #   repo.push('origin', mirror: true)
      #
      # @overload push(options = {})
      #   Push using the current branch's default remote and push configuration
      #
      #   @param options [Hash] push options (see option list below)
      #
      #   @option options [Boolean, nil] :all (nil) push all branches (`--all`)
      #
      #   @option options [Boolean, nil] :mirror (nil) push all refs under
      #     `refs/` to the remote (`--mirror`)
      #
      #     When `:tags` is also given, the separate tags push is suppressed.
      #
      #   @option options [Boolean, nil] :tags (nil) push all refs under
      #     `refs/tags/` in a second `git push` invocation (`--tags`)
      #
      #     When `:mirror` is also given, the tags push is suppressed because
      #     `--mirror` already includes tags.
      #
      #   @option options [Boolean, nil] :force (nil) force updates,
      #     overriding the fast-forward check (`--force`)
      #
      #     Alias: `:f`
      #
      #   @option options [Boolean, nil] :delete (nil) delete the named refs
      #     from the remote (`--delete`)
      #
      #   @option options [String, Array<String>] :push_option (nil) one or
      #     more server-side push option values (`--push-option=<value>`,
      #     repeatable)
      #
      #   @return [String] the stdout from the push command
      #
      # @overload push(remote, options = {})
      #   Push to the given remote using the current branch's default push configuration
      #
      #   @param remote [String] the remote name or URL to push to
      #
      #   @param options [Hash] push options (see option list below)
      #
      #   @option options [Boolean, nil] :all (nil) push all branches (`--all`)
      #
      #   @option options [Boolean, nil] :mirror (nil) push all refs under
      #     `refs/` to the remote (`--mirror`)
      #
      #     When `:tags` is also given, the separate tags push is suppressed.
      #
      #   @option options [Boolean, nil] :tags (nil) push all refs under
      #     `refs/tags/` in a second `git push` invocation (`--tags`)
      #
      #     When `:mirror` is also given, the tags push is suppressed because
      #     `--mirror` already includes tags.
      #
      #   @option options [Boolean, nil] :force (nil) force updates,
      #     overriding the fast-forward check (`--force`)
      #
      #     Alias: `:f`
      #
      #   @option options [Boolean, nil] :delete (nil) delete the named refs
      #     from the remote (`--delete`)
      #
      #   @option options [String, Array<String>] :push_option (nil) one or
      #     more server-side push option values (`--push-option=<value>`,
      #     repeatable)
      #
      #   @return [String] the stdout from the push command
      #
      # @overload push(remote, branch, options = {})
      #   Push a branch or refspec to the given remote
      #
      #   @param remote [String] the remote name or URL to push to
      #
      #   @param branch [String] the branch name or refspec to push
      #
      #   @param options [Hash] push options (see option list below)
      #
      #   @option options [Boolean, nil] :all (nil) push all branches (`--all`)
      #
      #   @option options [Boolean, nil] :mirror (nil) push all refs under
      #     `refs/` to the remote (`--mirror`)
      #
      #     When `:tags` is also given, the separate tags push is suppressed.
      #
      #   @option options [Boolean, nil] :tags (nil) push all refs under
      #     `refs/tags/` in a second `git push` invocation (`--tags`)
      #
      #     When `:mirror` is also given, the tags push is suppressed because
      #     `--mirror` already includes tags.
      #
      #   @option options [Boolean, nil] :force (nil) force updates,
      #     overriding the fast-forward check (`--force`)
      #
      #     Alias: `:f`
      #
      #   @option options [Boolean, nil] :delete (nil) delete the named refs
      #     from the remote (`--delete`)
      #
      #   @option options [String, Array<String>] :push_option (nil) one or
      #     more server-side push option values (`--push-option=<value>`,
      #     repeatable)
      #
      #   @return [String] the stdout from the push command
      #
      #   @raise [ArgumentError] if `remote` is nil when `branch` is given
      #
      # @overload push(remote, branch, tags)
      #   Backward-compatible shorthand for `push(remote, branch, tags: tags)`
      #
      #   @param remote [String] the remote name or URL to push to
      #
      #   @param branch [String] the branch name or refspec to push
      #
      #   @param tags [Boolean] whether to push all tags; equivalent to `tags: tags`
      #
      #   @return [String] the stdout from the push command
      #
      #   @raise [ArgumentError] if a branch is given and remote is nil
      #
      # @raise [ArgumentError] when unsupported option keys are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def push(remote = nil, branch = nil, opts = nil)
        remote, branch, opts = Private.normalize_push_args(remote, branch, opts)
        SharedPrivate.assert_valid_opts!(PUSH_ALLOWED_OPTS, **opts)
        raise ArgumentError, 'remote is required if branch is specified' if !remote && branch

        first_result = Private.push_refs(@execution_context, remote, branch, opts)
        return first_result.stdout unless Private.push_tags_separately?(opts)

        Private.push_tags(@execution_context, remote, opts).stdout
      end

      # Option keys accepted by {#remote_add}
      #
      # Derived from the 4.x `REMOTE_ADD_OPTION_MAP` in `Git::Lib`.
      REMOTE_ADD_ALLOWED_OPTS = %i[fetch track].freeze
      private_constant :REMOTE_ADD_ALLOWED_OPTS

      # Register a new remote in the local repository
      #
      # Associates `name` with `url` and optionally fetches immediately or
      # configures which branches are tracked.
      #
      # @example Add a remote
      #   repo.remote_add('upstream', 'https://github.com/user/repo.git')
      #
      # @example Add a remote and fetch immediately
      #   repo.remote_add('upstream', 'https://github.com/user/repo.git', fetch: true)
      #
      # @example Add a remote tracking a specific branch
      #   repo.remote_add('upstream', 'https://github.com/user/repo.git', track: 'main')
      #
      # @param name [String] the name for the new remote
      #
      # @param url [String, Git::Repository] the URL of the remote repository
      #
      #   A {Git::Repository} instance is accepted for local references and converted
      #   to `url.repo.to_s`.
      #
      # @param opts [Hash] options for adding the remote
      #
      # @option opts [Boolean, nil] :fetch (nil) fetch from the remote immediately
      #   after adding it (`-f`)
      #
      #   The deprecated alias `:with_fetch` is accepted and normalized
      #   automatically.
      #
      # @option opts [String, nil] :track (nil) track only the given branch during
      #   fetch (`-t`)
      #
      # @return [Git::Remote] the newly added remote
      #
      # @raise [ArgumentError] when unsupported option keys are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      def remote_add(name, url, opts = {})
        url = url.repo.to_s if url.is_a?(Git::Repository)
        opts = Private.normalize_add_remote_keys(opts)
        SharedPrivate.assert_valid_opts!(REMOTE_ADD_ALLOWED_OPTS, **opts)
        Git::Commands::Remote::Add.new(@execution_context).call(name, url, **opts)

        Git::Remote.new(self, name)
      end

      # @param name [String] the name for the new remote
      #
      # @param url [String, Git::Repository] the URL of the remote repository
      #
      #   A {Git::Repository} instance is accepted for local references and converted
      #   to `url.repo.to_s`.
      #
      # @param opts [Hash] options for adding the remote
      #
      # @option opts [Boolean, nil] :fetch (nil) fetch from the remote immediately
      #   after adding it (`-f`)
      #
      #   The deprecated alias `:with_fetch` is accepted and normalized
      #   automatically.
      #
      # @option opts [String, nil] :track (nil) track only the given branch during
      #   fetch (`-t`)
      #
      # @return [Git::Remote] the newly added remote
      #
      # @raise [ArgumentError] when unsupported option keys are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      # @deprecated Use {#remote_add} instead
      #
      def add_remote(name, url, opts = {})
        Git::Deprecation.warn(
          'Git::Repository#add_remote is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#remote_add instead.'
        )
        remote_add(name, url, opts)
      end

      # Removes a remote from this repository
      #
      # Deletes the remote named `name` along with its associated configuration,
      # tracking references, and remote-tracking branches.
      #
      # @example Remove a remote named 'upstream'
      #   repo.remote_remove('upstream')
      #
      # @param name [String] the name of the remote to remove
      #
      # @return [Git::CommandLineResult] the result of calling `git remote remove`
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      def remote_remove(name)
        Git::Commands::Remote::Remove.new(@execution_context).call(name)
      end

      # @param name [String] the name of the remote to remove
      #
      # @return [Git::CommandLineResult] the result of calling `git remote remove`
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      # @deprecated Use {#remote_remove} instead
      #
      def remove_remote(name)
        Git::Deprecation.warn(
          'Git::Repository#remove_remote is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#remote_remove instead.'
        )
        remote_remove(name)
      end

      # Sets the URL for an existing remote
      #
      # Replaces the fetch URL configured for the remote named `name`.
      #
      # @example Set the URL for a remote
      #   repo.remote_set_url('origin', 'https://github.com/user/repo.git')
      #
      # @example Set the URL from a local repository reference
      #   source = Git.open('/path/to/source')
      #   repo.remote_set_url('origin', source)
      #
      # @param name [String] the name of the remote to update
      #
      # @param url [String, Git::Repository] the new URL for the remote
      #
      #   A {Git::Repository} instance is accepted for local references and converted
      #   to `url.repo.to_s`.
      #
      # @return [Git::Remote] the updated remote
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      def remote_set_url(name, url)
        url = url.repo.to_s if url.is_a?(Git::Repository)
        Git::Commands::Remote::SetUrl.new(@execution_context).call(name, url)

        Git::Remote.new(self, name)
      end

      # @param name [String] the name of the remote to update
      #
      # @param url [String, Git::Repository] the new URL for the remote
      #
      #   A {Git::Repository} instance is accepted for local references and converted
      #   to `url.repo.to_s`.
      #
      # @return [Git::Remote] the updated remote
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      # @deprecated Use {#remote_set_url} instead
      #
      def set_remote_url(name, url)
        Git::Deprecation.warn(
          'Git::Repository#set_remote_url is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#remote_set_url instead.'
        )
        remote_set_url(name, url)
      end

      # Configures which branches are fetched for a remote
      #
      # Uses `git remote set-branches` to set or append fetch refspecs. When the
      # `add:` option is `false`, the `--add` flag is not passed to the git
      # command and the tracked branch list is replaced.
      #
      # @example Replace fetched branches with a single glob pattern
      #   repo.remote_set_branches('origin', 'feature/*')
      #
      # @example Append a glob pattern to existing fetched branches
      #   repo.remote_set_branches('origin', 'release/*', add: true)
      #
      # @example Configure multiple explicit branches
      #   repo.remote_set_branches('origin', 'main', 'development', 'hotfix')
      #
      # @param name [String] the remote name (for example, `"origin"`)
      #
      # @param branches [Array<String>] branch names or globs (for example, `'*'`)
      #
      # @param add [Boolean] when `true`, append to existing refspecs instead of
      #   replacing them
      #
      # @return [void]
      #
      # @raise [ArgumentError] when no branches are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      def remote_set_branches(name, *branches, add: false)
        branch_list = branches.flatten
        raise ArgumentError, 'branches are required' if branch_list.empty?

        Git::Commands::Remote::SetBranches.new(@execution_context).call(name, *branch_list, add: add)

        nil
      end

      # Return the git configuration entries for a named remote
      #
      # Reads `git config --list` and returns all entries whose keys begin with
      # `remote.<name>.`, with the `remote.<name>.` prefix stripped. This
      # typically yields at least `"url"` and `"fetch"` for a configured remote.
      #
      # @example Retrieve the config for the 'origin' remote
      #   repo.config_remote('origin')
      #   #=> {
      #   #     'url'   => 'https://github.com/user/repo.git',
      #   #     'fetch' => '+refs/heads/*:refs/remotes/origin/*'
      #   #   }
      #
      # @param name [String] the name of the remote (e.g. `"origin"`)
      #
      # @return [Hash{String => String}] configuration entries for the remote,
      #   keyed without the `remote.<name>.` prefix
      #
      #   Returns an empty hash when no entries are found.
      #
      # @raise [Git::FailedError] when git exits with a non-zero status
      #
      def config_remote(name)
        prefix = "remote.#{name}."
        Private.config_list(@execution_context).each_with_object({}) do |(key, value), hsh|
          hsh[key.delete_prefix(prefix)] = value if key.start_with?(prefix)
        end
      end

      # Returns a {Git::Remote} object for the named remote
      #
      # @example Get the default 'origin' remote
      #   repo.remote  #=> #<Git::Remote 'origin'>
      #
      # @example Get a named remote
      #   repo.remote('upstream')  #=> #<Git::Remote 'upstream'>
      #
      # @param name [String] the remote name (defaults to `'origin'`)
      #
      # @return [Git::Remote] the remote object
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def remote(name = 'origin')
        Git::Remote.new(self, name)
      end

      # Returns all configured remotes as {Git::Remote} objects
      #
      # @example List all remotes
      #   repo.remotes  #=> [#<Git::Remote 'origin'>, #<Git::Remote 'upstream'>]
      #
      # @return [Array<Git::Remote>] one {Git::Remote} for each configured remote
      #
      #   Returns an empty array when no remotes are configured.
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def remotes
        result = Git::Commands::Remote::List.new(@execution_context).call
        result.stdout.split("\n").map { |name| Git::Remote.new(self, name) }
      end

      # Option keys accepted by {#ls_remote}
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      LS_REMOTE_ALLOWED_OPTS = %i[
        branches b heads h tags t refs upload_pack quiet q exit_code sort server_option o timeout
      ].freeze
      private_constant :LS_REMOTE_ALLOWED_OPTS

      # List references available in a remote repository
      #
      # Queries a remote for its available refs and returns a structured Hash
      # mapping ref types to name/sha pairs. The remote is contacted but no local
      # objects are created or updated.
      #
      # @example List all refs from the local repository
      #   repo.ls_remote
      #   # => {"head"=>{ref: "HEAD", sha: "abc123"},
      #   #     "branches"=>{"main"=>{ref: "refs", sha: "abc123"}}}
      #
      # @example List all refs from a named remote
      #   repo.ls_remote('origin')
      #   # => {"head"=>..., "branches"=>..., "tags"=>...}
      #
      # @example List only tags from a named remote
      #   repo.ls_remote('origin', tags: true)
      #   # => {"tags"=>{"v1.0"=>{ref: "refs", sha: "def456"}}}
      #
      # @param location [String, nil] the remote name or URL to query; defaults to
      #   `'.'` (the local repository) when nil
      #
      # @param opts [Hash] options for the ls-remote command
      #
      # @option opts [Boolean, nil] :branches (nil) limit output to refs under
      #   `refs/heads/`; alias: `:b`
      #
      # @option opts [Boolean, nil] :heads (nil) limit output to refs under
      #   `refs/heads/`; kept for backward compatibility; alias: `:h`
      #
      # @option opts [Boolean, nil] :tags (nil) limit output to refs under
      #   `refs/tags/`; alias: `:t`
      #
      # @option opts [Boolean, nil] :refs (nil) exclude peeled tags and pseudorefs
      #   like `HEAD` from the output
      #
      # @option opts [Numeric] :timeout (nil) execution timeout in seconds
      #
      # @return [Hash{String => Hash}] a Hash keyed by ref type (e.g. `"head"`,
      #   `"branches"`, `"tags"`; other git namespace segments may appear for
      #   non-standard refs); for named refs the value is a Hash keyed by ref name
      #   mapping to `{ ref: String, sha: String }`; for the `"head"` entry the value
      #   is `{ ref: String, sha: String }` directly
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 2)
      #
      # @note The `:ref` value in each pair is only the **first path segment** of the
      #   full git ref (e.g. `"refs"` for `refs/heads/main`), not the complete ref
      #   path. This matches the behavior of 4.x. See
      #   [issue 1416](https://github.com/ruby-git/ruby-git/issues/1416) for the
      #   planned fix.
      #
      def ls_remote(location = nil, opts = {})
        SharedPrivate.assert_valid_opts!(LS_REMOTE_ALLOWED_OPTS, **opts)
        repository = location || '.'
        output_lines = Git::Commands::LsRemote.new(@execution_context).call(repository, **opts).stdout.split("\n")
        Git::Parsers::LsRemote.parse_output(output_lines)
      end

      # Helpers private to the `RemoteOperations` topic module
      #
      # @api private
      #
      module Private
        module_function

        # Resolve the (remote, opts) pair for {#fetch}, supporting the hash-only form
        #
        # `fetch` may be called as `fetch(remote, opts)` or `fetch(opts)`. When a bare
        # options hash is passed the remote is treated as nil. A `:ref` is only
        # meaningful with an explicit remote, so requesting one without a remote (it
        # would otherwise be silently promoted to the remote-name slot) is rejected.
        #
        # @param remote [String, Hash, nil] the remote name, or an options hash
        #
        # @param opts [Hash] the options hash when remote is given positionally
        #
        # @return [Array(String, Hash), Array(nil, Hash)] the resolved remote and opts
        #
        # @raise [ArgumentError] when :ref is supplied without an explicit remote
        #
        # @api private
        #
        def resolve_fetch_target(remote, opts)
          if remote.is_a?(Hash)
            opts = remote
            remote = nil
          end

          raise ArgumentError, ':ref requires an explicit remote' if remote.nil? && opts.key?(:ref)

          [remote, opts]
        end

        # Normalize dash-style option keys to their underscore equivalents
        #
        # Converts any key in {FETCH_KEY_NORMALIZATIONS} from its dash-style symbol
        # form (e.g., `:'update-head-ok'`) to the canonical underscore-style form
        # (e.g., `:update_head_ok`). Unrecognized keys are returned unchanged.
        #
        # @param opts [Hash] the raw options hash passed by the caller
        #
        # @return [Hash] a new hash with all applicable keys normalized
        #
        # @api private
        #
        def normalize_fetch_keys(opts)
          opts.transform_keys do |k|
            sym = k.is_a?(Symbol) ? k : k.to_sym
            FETCH_KEY_NORMALIZATIONS.fetch(sym, sym)
          end
        end

        # Normalize the flexible argument list accepted by {RemoteOperations#push}
        #
        # Handles three call forms:
        # - `push(opts)` — Hash promoted from `remote` position
        # - `push(remote, opts)` — Hash promoted from `branch` position
        # - `push(remote, branch, true|false)` — Boolean `opts` converted to
        #   `{ tags: opts }` for backward compatibility
        #
        # @param remote [String, Hash, nil] remote name, URL, or opts hash
        #
        # @param branch [String, Hash, nil] branch/refspec, or opts hash
        #
        # @param opts [Hash, Boolean, nil] options hash or legacy Boolean shorthand
        #
        # @return [Array((String, nil), (String, nil), Hash)] normalized [remote, branch, opts]
        #
        # @api private
        #
        def normalize_push_args(remote, branch, opts)
          if branch.is_a?(Hash)
            opts = branch
            branch = nil
          elsif remote.is_a?(Hash)
            opts = remote
            remote = nil
          end

          opts ||= {}

          # Backwards compatibility for `push(remote, branch, true)` to push tags
          # without requiring the caller to use keyword arguments

          opts = { tags: opts } if [true, false].include?(opts)
          [remote, branch, opts]
        end

        # Issue the refs push (first push when `:tags` is given separately)
        #
        # Strips `:tags` from the options so that only refs — not tags — are pushed
        # in this first call. Tags are pushed in a separate call when
        # {push_tags_separately?} is true.
        #
        # @param execution_context [Git::ExecutionContext::Repository] the repository execution context
        #
        # @param remote [String, nil] remote name or URL
        #
        # @param branch [String, nil] branch or refspec
        #
        # @param opts [Hash] push options (`:tags` key will be stripped)
        #
        # @return [Git::CommandLineResult]
        #
        # @api private
        #
        def push_refs(execution_context, remote, branch, opts)
          positionals = [remote, branch].compact
          Git::Commands::Push.new(execution_context).call(*positionals, **opts.except(:tags))
        end

        # Return true when tags must be pushed in a second separate invocation
        #
        # Tags are pushed separately when `:tags` is truthy AND `:mirror` is not set.
        # When `:mirror` is set, the mirror push already includes all refs and tags,
        # so a second tags-only call would be redundant.
        #
        # @param opts [Hash] the normalized push options
        #
        # @return [Boolean]
        #
        # @api private
        #
        def push_tags_separately?(opts)
          opts[:tags] && !opts[:mirror]
        end

        # Issue the tags push (second push when `:tags` is requested without `:mirror`)
        #
        # @param execution_context [Git::ExecutionContext::Repository] the repository execution context
        #
        # @param remote [String, nil] remote name or URL
        #
        # @param opts [Hash] push options (`:tags` key included to emit `--tags`)
        #
        # @return [Git::CommandLineResult]
        #
        # @api private
        #
        def push_tags(execution_context, remote, opts)
          Git::Commands::Push.new(execution_context).call(*[remote].compact, **opts)
        end

        # Normalize deprecated option keys for {#remote_add} to their canonical equivalents
        #
        # Renames the deprecated `:with_fetch` key to `:fetch`, removing it from
        # the copy. When both keys are present, `:with_fetch` takes precedence.
        #
        # @param opts [Hash] the raw options hash passed by the caller
        #
        # @return [Hash] a new hash with all applicable keys normalized
        #
        # @api private
        #
        def normalize_add_remote_keys(opts)
          normalized = opts.dup
          normalized[:fetch] = normalized.delete(:with_fetch) if normalized.key?(:with_fetch)
          normalized
        end

        # Retrieve all config entries as a flat hash
        #
        # Runs `git config --list` and parses each `key=value` line into a hash.
        # When no value is present for a key, the value defaults to an empty string.
        #
        # @param execution_context [Git::ExecutionContext::Repository] the
        #   execution context for the repository
        #
        # @return [Hash{String => String}] all visible config entries, keyed by
        #   their full dotted key names
        #
        #   For example, `"remote.origin.url"` is a valid key.
        #
        # @api private
        #
        def config_list(execution_context)
          lines = Git::Commands::ConfigOptionSyntax::List.new(execution_context).call.stdout.split("\n")
          lines.each_with_object({}) do |line, hsh|
            key, value = line.split('=', 2)
            hsh[key] = value || ''
          end
        end
      end
      private_constant :Private
    end
  end
end
