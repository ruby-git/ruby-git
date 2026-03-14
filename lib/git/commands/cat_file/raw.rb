# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module CatFile
      # Queries a single git object by name passed as a CLI argument
      #
      # Runs `git cat-file` in non-batch mode. Exactly one mode flag or a `<type>`
      # operand must be supplied:
      #
      # - **`-e`** — exit 0 if the object exists and is valid, exit 1 otherwise;
      #   no output is written to stdout
      # - **`-t`** — print the object type (`blob`, `tree`, `commit`, or `tag`)
      # - **`-s`** — print the object size in bytes
      # - **`-p`** — pretty-print the object content (format varies by type)
      # - **`<type>`** — print the raw content after validating the object is of
      #   the given type (or trivially dereferenceable to it)
      #
      # For queries across multiple objects, use {CatFile::Batch}.
      # For filter-processed content, use {CatFile::Filtered}.
      #
      # @see Git::Commands::CatFile
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      # @api private
      #
      class Raw < Base
        arguments do
          literal 'cat-file'

          # Exit 0 if object exists and is valid; exit 1 otherwise (no output)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt--e
          flag_option :e

          # Pretty-print the object content based on its type
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt--p
          flag_option :p

          # Print the object type (`blob`, `tree`, `commit`, or `tag`)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt--t
          flag_option :t

          # Print the object size in bytes
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt--s
          flag_option :s

          # Map committer/author identities through the mailmap before reporting size
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---use-mailmap
          flag_option :use_mailmap, negatable: true

          # Stream stdout to this IO object instead of buffering in memory.
          # When provided, {#call} dispatches to the streaming execution path.
          execution_option :out

          # Expected object type — one of `commit`, `tree`, `blob`, or `tag`.
          # Git also accepts a type that the object is trivially dereferenceable to
          # (e.g. `tree` against a commit ref, `blob` against a tag that points to one).
          operand :type

          # Object name: SHA, ref, `HEAD`, treeish path reference, etc.
          operand :object, required: true
        end

        # Execute `git cat-file` for a single object.
        #
        # Exactly one mode must be selected: pass one of `e: true`, `p: true`,
        # `t: true`, `s: true`, or a positional `type` argument.
        #
        # @overload call(object, e: true, **options)
        #   Check whether an object exists
        #
        #   @param object [String] object name (SHA, ref, `HEAD`, treeish path, etc.)
        #
        #   @param e [Boolean] enable existence-check mode
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :use_mailmap (false) Map identities through mailmap
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Exit status 0 means the object exists; exit status 1 means it does not
        #
        #   @raise [Git::FailedError] if git exits with a status other than 0 or 1
        #
        # @overload call(object, t: true, **options)
        #   Print the object type
        #
        #   @param object [String] object name
        #
        #   @param t [Boolean] enable type-query mode
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :use_mailmap (false) Map identities through mailmap
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains the object type string
        #
        #   @raise [Git::FailedError] if the object does not exist
        #
        # @overload call(object, s: true, **options)
        #   Print the object size in bytes
        #
        #   @param object [String] object name
        #
        #   @param s [Boolean] enable size-query mode
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :use_mailmap (false) Map identities through mailmap
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains the object size as a decimal string
        #
        #   @raise [Git::FailedError] if the object does not exist
        #
        # @overload call(object, p: true, **options)
        #   Pretty-print the object content
        #
        #   @param object [String] object name
        #
        #   @param p [Boolean] enable pretty-print mode
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :use_mailmap (false) Map identities through mailmap
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains the formatted object content
        #
        #   @raise [Git::FailedError] if the object does not exist
        #
        # @overload call(type, object, **options)
        #   Print the raw content, validating the object is of the given type
        #
        #   @param type [String] expected object type — `commit`, `tree`, `blob`, or `tag`
        #
        #   @param object [String] object name
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :use_mailmap (false) Map identities through mailmap
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains the raw object content
        #
        #   @raise [Git::FailedError] if the object does not exist or is not of the
        #     given type
        def call(*, **)
          bound = args_definition.bind(*, **)
          result = execute_command(bound)

          # `-e` treats exit 1 as a meaningful result (object not found), but any other
          # non-zero exit (e.g. 128 for a corrupt object database) is still a failure.
          # All other modes treat every non-zero exit as a failure.
          allowed = result.status.success? || (bound.e? && result.status.exitstatus == 1)
          raise Git::FailedError, result unless allowed

          result
        end
      end
    end
  end
end
