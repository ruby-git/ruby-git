# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git clone` command
    #
    # Clones a repository into a newly created directory.
    #
    # @example Typical usage
    #   clone = Git::Commands::Clone.new(execution_context)
    #   clone.call('https://github.com/user/repo.git')
    #   clone.call('https://github.com/user/repo.git', 'local-dir')
    #   clone.call('https://github.com/user/repo.git', 'local-dir', bare: true)
    #   clone.call('https://github.com/user/repo.git', 'local-dir', depth: 1)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-clone/2.53.0
    #
    # @see https://git-scm.com/docs/git-clone git-clone
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Clone < Git::Commands::Base
      arguments do
        literal 'clone'
        value_option :template, inline: true # --template=<template-directory>
        flag_option %i[local l], negatable: true # --local / --no-local (alias: :l)
        flag_option %i[shared s] # --shared (alias: :s)
        flag_option :no_hardlinks # --no-hardlinks
        flag_option %i[quiet q] # --quiet (alias: :q)
        flag_option %i[verbose v] # --verbose (alias: :v)
        flag_option :progress # --progress
        flag_option %i[no_checkout n] # --no-checkout (alias: :n)
        flag_option :bare # --bare
        flag_option :mirror # --mirror
        value_option %i[origin o] # --origin <name> (alias: :o)
        value_option %i[branch b] # --branch <name> (alias: :b)
        value_option :revision, inline: true # --revision=<rev>
        value_option %i[upload_pack u] # --upload-pack <upload-pack> (alias: :u)
        value_option :reference, repeatable: true # --reference <repository>
        value_option :reference_if_able, repeatable: true # --reference-if-able <repository>
        flag_option :dissociate # --dissociate
        value_option :separate_git_dir, inline: true # --separate-git-dir=<git-dir>
        value_option :server_option, inline: true, repeatable: true # --server-option=<option>
        value_option :depth # --depth <depth>
        value_option :shallow_since, inline: true # --shallow-since=<date>
        value_option :shallow_exclude, inline: true, repeatable: true # --shallow-exclude=<ref>
        flag_option :single_branch, negatable: true # --single-branch / --no-single-branch
        flag_option :tags, negatable: true # --tags / --no-tags
        flag_or_value_option :recurse_submodules, inline: true, repeatable: true # --recurse-submodules[=<pathspec>]
        flag_option :shallow_submodules, negatable: true # --shallow-submodules / --no-shallow-submodules
        flag_option :remote_submodules, negatable: true # --remote-submodules / --no-remote-submodules
        value_option %i[jobs j] # --jobs <n> (alias: :j)
        flag_option :sparse # --sparse
        flag_option :reject_shallow, negatable: true # --reject-shallow / --no-reject-shallow
        value_option :filter, inline: true # --filter=<filter-spec>
        flag_option :also_filter_submodules # --also-filter-submodules
        value_option %i[config c], repeatable: true # --config <key>=<value> (alias: :c)
        value_option :bundle_uri, inline: true # --bundle-uri=<uri>
        value_option :ref_format, inline: true # --ref-format=<ref-format>
        end_of_options
        operand :repository, required: true
        operand :directory
        execution_option :timeout
        execution_option :chdir
      end

      # @!method call(*, **)
      #
      #   @overload call(repository, directory = nil, **options)
      #
      #     Execute the `git clone` command
      #
      #     @param repository [String] the URL or path of the repository to clone
      #
      #     @param directory [String, nil] the directory to clone into; git derives the
      #       name from the repository URL when omitted
      #
      #     @param options [Hash] command options
      #
      #     @option options [String] :template (nil) directory from which templates
      #       will be used
      #
      #     @option options [Boolean] :local (nil) bypass the normal Git-aware transport
      #       for local clones; pass false to emit --no-local
      #
      #       Alias: `:l`
      #
      #     @option options [Boolean] :shared (false) set up a shared clone using
      #       alternates instead of hardlinks
      #
      #       Alias: `:s`
      #
      #     @option options [Boolean] :no_hardlinks (false) force file-copy instead of
      #       hardlinks when cloning from a local filesystem
      #
      #     @option options [Boolean] :quiet (false) suppress progress output to stderr
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean] :verbose (false) run verbosely
      #
      #       Alias: `:v`
      #
      #     @option options [Boolean] :progress (false) force progress status even when
      #       stderr is not a terminal
      #
      #     @option options [Boolean] :no_checkout (false) skip checking out HEAD after
      #       the clone
      #
      #       Alias: `:n`
      #
      #     @option options [Boolean] :bare (false) clone as a bare repository
      #
      #     @option options [Boolean] :mirror (false) set up a mirror clone (implies
      #       --bare)
      #
      #     @option options [String] :origin (nil) name of the remote to use instead of
      #       "origin"
      #
      #       Alias: `:o`
      #
      #     @option options [String] :branch (nil) branch to check out after cloning
      #
      #       Alias: `:b`
      #
      #     @option options [String] :revision (nil) detach HEAD at the given revision
      #       after cloning; incompatible with :branch and :mirror
      #
      #     @option options [String] :upload_pack (nil) path to git-upload-pack on the
      #       remote (ssh only)
      #
      #       Alias: `:u`
      #
      #     @option options [String, Array<String>] :reference (nil) borrow objects from
      #       one or more reference repositories
      #
      #     @option options [String, Array<String>] :reference_if_able (nil) like
      #       :reference but skip with a warning when the reference does not exist
      #
      #     @option options [Boolean] :dissociate (false) stop borrowing from reference
      #       repositories after the clone is complete
      #
      #     @option options [String] :separate_git_dir (nil) place the git directory at
      #       the given path and create a gitfile symlink in the working tree
      #
      #     @option options [String, Array<String>] :server_option (nil) protocol-v2
      #       server options
      #
      #     @option options [Integer, String] :depth (nil) create a shallow clone with
      #       the specified number of commits
      #
      #     @option options [String] :shallow_since (nil) create a shallow clone with
      #       history after the specified date
      #
      #     @option options [String, Array<String>] :shallow_exclude (nil) exclude
      #       commits reachable from the specified remote branch or tag
      #
      #     @option options [Boolean] :single_branch (nil) clone only the history for
      #       one branch; pass false to emit --no-single-branch
      #
      #     @option options [Boolean] :tags (nil) control whether tags are cloned; pass
      #       false to emit --no-tags
      #
      #     @option options [Boolean, String, Array<String>] :recurse_submodules (nil)
      #       initialize submodules after cloning; pass true for all submodules or a
      #       pathspec string/array for a subset
      #
      #     @option options [Boolean] :shallow_submodules (nil) clone submodules with
      #       depth 1; pass false to emit --no-shallow-submodules
      #
      #     @option options [Boolean] :remote_submodules (nil) use submodule
      #       remote-tracking branch status; pass false to emit --no-remote-submodules
      #
      #     @option options [Integer, String] :jobs (nil) number of submodules fetched
      #       concurrently
      #
      #       Alias: `:j`
      #
      #     @option options [Boolean] :sparse (false) enable sparse checkout with
      #       top-level files only
      #
      #     @option options [Boolean] :reject_shallow (nil) fail if source is shallow;
      #       pass false to emit --no-reject-shallow
      #
      #     @option options [String] :filter (nil) specify a partial clone filter
      #       (e.g., 'blob:none', 'tree:0')
      #
      #     @option options [Boolean] :also_filter_submodules (false) apply the partial
      #       clone filter to submodules; requires :filter and :recurse_submodules
      #
      #     @option options [String, Array<String>] :config (nil) set configuration
      #       variables in the newly-created repository
      #
      #       Alias: `:c`
      #
      #     @option options [String] :bundle_uri (nil) fetch a bundle from the given URI
      #       before fetching from the remote
      #
      #     @option options [String] :ref_format (nil) specify the ref storage format
      #       (e.g., 'files', 'reftable')
      #
      #     @option options [Numeric, nil] :timeout (nil) the number of seconds to wait
      #       for the command to complete; if nil, uses the global timeout from
      #       {Git::Config}; if 0, no timeout is enforced
      #
      #     @option options [String, nil] :chdir (nil) the working directory in which to
      #       run the git clone command
      #
      #     @return [Git::CommandLineResult] the result of calling `git clone`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
      #
    end
  end
end
