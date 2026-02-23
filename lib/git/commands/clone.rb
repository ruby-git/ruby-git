# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git clone` command
    #
    # This command clones a repository into a newly created directory.
    #
    # @api private
    #
    # @example Basic usage
    #   clone = Git::Commands::Clone.new(execution_context)
    #   result = clone.call('https://github.com/user/repo.git', 'local-dir')
    #
    # @example With options
    #   clone = Git::Commands::Clone.new(execution_context)
    #   result = clone.call('https://github.com/user/repo.git', 'local-dir', bare: true, depth: 1)
    #
    class Clone < Git::Commands::Base
      arguments do
        literal 'clone'
        value_option :template, inline: true
        flag_option %i[local l], negatable: true
        flag_option %i[shared s]
        flag_option :no_hardlinks
        flag_option %i[no_checkout n]
        flag_option :bare
        flag_option :mirror
        value_option %i[origin o]
        value_option %i[branch b]
        value_option :revision, inline: true
        value_option %i[upload_pack u]
        value_option :reference, repeatable: true
        value_option :reference_if_able, repeatable: true
        flag_option :dissociate
        value_option :separate_git_dir, inline: true
        value_option :server_option, inline: true, repeatable: true
        value_option :depth
        value_option :shallow_since, inline: true
        value_option :shallow_exclude, inline: true, repeatable: true
        flag_option :single_branch, negatable: true
        flag_option :tags, negatable: true
        flag_or_value_option :recurse_submodules, inline: true, repeatable: true
        flag_option :shallow_submodules, negatable: true
        flag_option :remote_submodules, negatable: true
        value_option %i[jobs j]
        flag_option :sparse
        flag_option :reject_shallow, negatable: true
        value_option :filter, inline: true
        flag_option :also_filter_submodules
        value_option %i[config c], repeatable: true
        value_option :bundle_uri, inline: true
        value_option :ref_format, inline: true
        operand :repository, required: true, separator: '--'
        operand :directory
        execution_option :timeout
        execution_option :chdir

        conflicts :revision, :branch
        conflicts :revision, :mirror
        conflicts :bundle_uri, :depth
        conflicts :bundle_uri, :shallow_since
        conflicts :bundle_uri, :shallow_exclude
        requires :filter,             when: :also_filter_submodules
        requires :recurse_submodules, when: :also_filter_submodules
        allowed_values :ref_format, in: %w[files reftable]
      end

      # @!method call(*, **)
      #
      #   Execute the git clone command
      #
      #   @overload call(repository, directory = nil, **options)
      #
      #     @param repository [String] the URL of the repository to clone
      #
      #     @param directory [String, nil] the directory to clone into.
      #       If nil, git derives the directory name from the repository URL.
      #
      #     @param options [Hash] command options
      #
      #     @option options [String] :template (nil) Directory from which templates will be used.
      #
      #     @option options [Boolean, nil] :local (nil) Bypass the normal Git-aware transport for local
      #       clones. Use false to emit --no-local. Alias: :l
      #
      #     @option options [Boolean] :shared (nil) Set up a shared clone using alternates instead
      #       of hardlinks. Alias: :s
      #
      #     @option options [Boolean] :no_hardlinks (nil) Force file-copy instead of hardlinks when
      #       cloning from a local filesystem.
      #
      #     @option options [Boolean] :no_checkout (nil) Skip checking out HEAD after the clone.
      #       Alias: :n
      #
      #     @option options [Boolean] :bare (nil) Clone as a bare repository
      #
      #     @option options [Boolean] :mirror (nil) Set up a mirror clone (implies --bare)
      #
      #     @option options [String] :origin (nil) Name of the remote (defaults to 'origin').
      #       Alias: :o
      #
      #     @option options [String] :branch (nil) The branch to checkout after cloning.
      #       Mutually exclusive with :revision. Alias: :b
      #
      #     @option options [String] :revision (nil) Detach HEAD at the given revision after cloning.
      #       Incompatible with :branch and :mirror.
      #
      #     @option options [String] :upload_pack (nil) Path to git-upload-pack on the remote (ssh only).
      #       Alias: :u
      #
      #     @option options [String, Array<String>] :reference (nil) Borrow objects from one or more
      #       reference repositories.
      #
      #     @option options [String, Array<String>] :reference_if_able (nil) Like :reference but skip
      #       with a warning if the reference directory does not exist. Repeatable.
      #
      #     @option options [Boolean] :dissociate (nil) Stop borrowing from reference repositories after
      #       the clone is complete.
      #
      #     @option options [String] :separate_git_dir (nil) Place the git directory at the given path
      #       and create a gitfile symlink in the working tree.
      #
      #     @option options [String, Array<String>] :server_option (nil) Protocol-v2 server options.
      #       Repeatable.
      #
      #     @option options [Integer, String] :depth (nil) Create a shallow clone with the specified
      #       number of commits
      #
      #     @option options [String] :shallow_since (nil) Create a shallow clone with history after
      #       the specified date.
      #
      #     @option options [String, Array<String>] :shallow_exclude (nil) Exclude commits reachable
      #       from the specified remote branch or tag. Repeatable.
      #
      #     @option options [Boolean, nil] :single_branch (nil) Clone only the history leading to the
      #       tip of a single branch. Use false to emit --no-single-branch.
      #
      #     @option options [Boolean, nil] :tags (nil) Control whether tags are cloned. Use false to
      #       emit --no-tags.
      #
      #     @option options [Boolean, String, Array<String>] :recurse_submodules (nil) Initialize all
      #       submodules after cloning. When true, uses `--recurse-submodules`. When a string, passes
      #       one pathspec. When an array of strings, emits repeated
      #       `--recurse-submodules=<pathspec>` options.
      #
      #     @option options [Boolean, nil] :shallow_submodules (nil) Clone submodules with depth 1.
      #       Use false to emit --no-shallow-submodules.
      #
      #     @option options [Boolean, nil] :remote_submodules (nil) Use submodule remote-tracking
      #       branch status. Use false to emit --no-remote-submodules.
      #
      #     @option options [Integer] :jobs (nil) Number of submodules fetched concurrently.
      #       Alias: :j
      #
      #     @option options [Boolean] :sparse (nil) Enable sparse checkout with top-level files only.
      #
      #     @option options [Boolean, nil] :reject_shallow (nil) Fail if source is shallow.
      #       Use false to emit --no-reject-shallow.
      #
      #     @option options [String] :filter (nil) Specify partial clone filter
      #       (e.g., 'blob:none', 'tree:0'). Required when :also_filter_submodules is set.
      #
      #     @option options [Boolean] :also_filter_submodules (nil) Apply the partial clone filter
      #       to submodules. Requires :filter and :recurse_submodules.
      #
      #     @option options [String, Array<String>] :config (nil) Configuration options to set.
      #       Alias: :c
      #
      #     @option options [String] :bundle_uri (nil) Fetch a bundle from the given URI before
      #       fetching from the remote. Incompatible with :depth, :shallow_since, and
      #       :shallow_exclude.
      #
      #     @option options [String] :ref_format (nil) Specify the ref storage format
      #       (e.g., 'files', 'reftable').
      #
      #     @option options [Numeric, nil] :timeout (nil) the number of seconds to wait
      #       for the command to complete. If nil, uses the global timeout from
      #       {Git::Config}. If 0, no timeout is enforced.
      #
      #     @option options [String, nil] :chdir (nil) the directory to run the git clone
      #       command in. When given, the clone is created relative to this directory.
      #
      #     @return [Git::CommandLineResult] the result of the git clone command
      #
      #     @raise [ArgumentError] if unsupported options are provided, if :single_branch is not
      #       true, false, or nil, if :also_filter_submodules is given without :filter or
      #       :recurse_submodules, if :revision is combined with :branch or :mirror, if :bundle_uri
      #       is combined with :depth, :shallow_since, or :shallow_exclude, or if any option fails
      #       validation
      #
      #     @see Git::Lib#command for details on timeout behavior and other execution options
    end
  end
end
