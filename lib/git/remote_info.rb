# frozen_string_literal: true

module Git
  # Value object representing a configured git remote
  #
  # Each instance holds the parsed configuration for a single remote as read
  # from the repository's git config. Multi-value fields (`:url`, `:push_url`,
  # `:fetch`, `:push`) are always `Array<String>` (never `nil`; may be empty).
  # All other fields are nilable except `:name`.
  #
  # @example Minimal remote (fetch-only, one URL)
  #   info = Git::RemoteInfo.new(
  #     name: 'origin',
  #     url: ['https://github.com/ruby-git/ruby-git.git'],
  #     push_url: [],
  #     fetch: ['+refs/heads/*:refs/remotes/origin/*'],
  #     push: []
  #   )
  #   info.name   # => "origin"
  #   info.url    # => ["https://github.com/ruby-git/ruby-git.git"]
  #   info.prune  # => nil
  #
  # @api public
  #
  # @!attribute [r] name
  #   @return [String] the name of the remote (e.g. `'origin'`)
  #
  # @!attribute [r] url
  #   @return [Array<String>] the fetch URL(s) for this remote (`remote.<name>.url`)
  #
  # @!attribute [r] push_url
  #   @return [Array<String>] the push URL(s) for this remote (`remote.<name>.pushurl`)
  #
  # @!attribute [r] fetch
  #   @return [Array<String>] the fetch refspec(s) for this remote (`remote.<name>.fetch`)
  #
  # @!attribute [r] push
  #   @return [Array<String>] the push refspec(s) for this remote (`remote.<name>.push`)
  #
  # @!attribute [r] mirror
  #   @return [Boolean, nil] `true`/`false` per `remote.<name>.mirror`, or `nil` when not set
  #
  # @!attribute [r] skip_default_update
  #   @return [Boolean, nil] `true`/`false` per `remote.<name>.skipDefaultUpdate`, or `nil` when not set
  #
  # @!attribute [r] tag_opt
  #   @return [String, nil] the tag-fetching option (`remote.<name>.tagOpt`), or `nil` when not set
  #
  # @!attribute [r] prune
  #   @return [Boolean, nil] `true`/`false` per `remote.<name>.prune`; `nil` inherits `fetch.prune`
  #
  # @!attribute [r] prune_tags
  #   @return [Boolean, nil] `true`/`false` per `remote.<name>.pruneTags`; `nil` inherits `fetch.pruneTags`
  #
  # @!attribute [r] receivepack
  #   @return [String, nil] the `git-receive-pack` path on the remote (`remote.<name>.receivepack`)
  #
  # @!attribute [r] uploadpack
  #   @return [String, nil] the `git-upload-pack` path on the remote (`remote.<name>.uploadpack`)
  #
  # @!attribute [r] promisor
  #   @return [Boolean, nil] `true`/`false` per `remote.<name>.promisor`, or `nil` when not set
  #
  # @!attribute [r] partial_clone_filter
  #   @return [String, nil] the partial-clone object filter (`remote.<name>.partialclonefilter`)
  #
  # @!attribute [r] vcs
  #   @return [String, nil] the VCS type for git-remote helpers (`remote.<name>.vcs`)
  #
  RemoteInfo = Data.define(
    :name,
    :url,
    :push_url,
    :fetch,
    :push,
    :mirror,
    :skip_default_update,
    :tag_opt,
    :prune,
    :prune_tags,
    :receivepack,
    :uploadpack,
    :promisor,
    :partial_clone_filter,
    :vcs
  ) do
    # Create a new RemoteInfo
    #
    # @param name [String] the name of the remote (required)
    #
    # @param url [Array<String>] fetch URLs (default `[]`)
    #
    # @param push_url [Array<String>] push URLs (default `[]`)
    #
    # @param fetch [Array<String>] fetch refspecs (default `[]`)
    #
    # @param push [Array<String>] push refspecs (default `[]`)
    #
    # @param mirror [Boolean, nil] mirror flag (default `nil`)
    #
    # @param skip_default_update [Boolean, nil] skip-default-update flag (default `nil`)
    #
    # @param tag_opt [String, nil] tag-fetching option (default `nil`)
    #
    # @param prune [Boolean, nil] prune flag (default `nil`)
    #
    # @param prune_tags [Boolean, nil] prune-tags flag (default `nil`)
    #
    # @param receivepack [String, nil] receive-pack path (default `nil`)
    #
    # @param uploadpack [String, nil] upload-pack path (default `nil`)
    #
    # @param promisor [Boolean, nil] promisor flag (default `nil`)
    #
    # @param partial_clone_filter [String, nil] partial-clone filter (default `nil`)
    #
    # @param vcs [String, nil] VCS type (default `nil`)
    #
    # @return [Git::RemoteInfo]
    #
    def initialize(
      name:,
      url: [],
      push_url: [],
      fetch: [],
      push: [],
      mirror: nil,
      skip_default_update: nil,
      tag_opt: nil,
      prune: nil,
      prune_tags: nil,
      receivepack: nil,
      uploadpack: nil,
      promisor: nil,
      partial_clone_filter: nil,
      vcs: nil
    )
      super(
        name:, url: Array(url), push_url: Array(push_url), fetch: Array(fetch),
        push: Array(push), mirror:, skip_default_update:, tag_opt:, prune:,
        prune_tags:, receivepack:, uploadpack:, promisor:, partial_clone_filter:,
        vcs:
      )
    end
  end
end
