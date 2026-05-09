# frozen_string_literal: true

require 'git/commands/fetch'
require 'git/repository/shared_private'

module Git
  class Repository
    # Mixin that adds remote operation facade methods to {Git::Repository}
    #
    # @api public
    #
    module RemoteOperations
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
      #     fetch; forwarded as positional arguments after the remote name
      #
      #   @return [String] the merged stdout from the fetch command
      #
      #   @raise [ArgumentError] when unsupported option keys are provided
      #
      #   @raise [Git::FailedError] when git exits with a non-zero status
      #
      def fetch(remote = 'origin', opts = {})
        if remote.is_a?(Hash)
          opts = remote
          remote = nil
        end

        opts = Private.normalize_fetch_keys(opts)
        SharedPrivate.assert_valid_opts!(FETCH_ALLOWED_OPTS, **opts)

        opts = opts.dup
        refspecs = Array(opts.delete(:ref)).compact
        positionals = [*([remote] if remote), *refspecs]

        Git::Commands::Fetch.new(@execution_context).call(*positionals, **opts, merge: true).stdout
      end

      # Helpers private to the `RemoteOperations` topic module
      #
      # @api private
      #
      module Private
        module_function

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
      end
      private_constant :Private
    end
  end
end
