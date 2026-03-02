# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module CatFile
      # Runs `git cat-file --batch-check` to retrieve metadata for one or more git objects
      #
      # Accepts object names via stdin using the batch protocol. For each named object,
      # git writes one line to stdout in the format `<sha> <type> <size>`.
      # If an object is not found, the line is `<name> missing`.
      #
      # @see Git::Commands::CatFile Git::Commands::CatFile
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      # @api private
      #
      # @example Query metadata for commit objects
      #   cmd = Git::Commands::CatFile::ObjectMeta.new(execution_context)
      #   result = cmd.call('HEAD', 'HEAD~1', 'v2.3.0')
      #   result.stdout
      #   # => "abc1234... commit 250\ndef5678... commit 198\nghi9012... commit 301\n"
      #
      # @example Enumerate all objects in the repository
      #   cmd = Git::Commands::CatFile::ObjectMeta.new(execution_context)
      #   result = cmd.call(batch_all_objects: true)
      #
      class ObjectMeta < Base
        arguments do
          literal 'cat-file'
          literal '--batch-check'

          # Output all objects in the repository without requiring stdin input
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---batch-all-objects
          flag_option :batch_all_objects

          # Makes `--batch-all-objects` output objects in an arbitrary, implementation-defined order,
          # which may be faster on large repositories
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---unordered
          flag_option :unordered

          # When using `--batch-all-objects`, follow symlinks inside sub-trees
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---follow-symlinks
          flag_option :follow_symlinks

          # Allow an unknown type object to be queried without erroring out
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---allow-unknown-type
          flag_option :allow_unknown_type

          # Object names are passed via stdin batch protocol, not argv
          operand :objects, repeatable: true, skip_cli: true

          conflicts :objects, :batch_all_objects
          requires_one_of :objects, :batch_all_objects
        end

        # Returns metadata (sha, type, size) for each named git object
        #
        # Object names are passed to the git process's stdin using the `--batch-check`
        # streaming protocol.
        #
        # @overload call(*objects, **options)
        #   Returns metadata for one or more named git objects
        #
        #   @param objects [Array<String>] One or more object names (SHAs, refs, `HEAD`, etc.)
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :unordered (false) Unordered output; may be faster
        #     for large repositories
        #
        #   @option options [Boolean] :follow_symlinks (false) Follow symlinks inside
        #     sub-trees
        #
        #   @option options [Boolean] :allow_unknown_type (false) Suppress errors for
        #     objects of unknown type
        #
        # @overload call(batch_all_objects: true, **options)
        #   Returns metadata for every object in the repository without reading stdin
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :batch_all_objects (true) Enumerate all objects
        #     in the repository; stdin is not read
        #
        #   @option options [Boolean] :unordered (false) Unordered output; may be faster
        #     for large repositories
        #
        #   @option options [Boolean] :follow_symlinks (false) Follow symlinks inside
        #     sub-trees
        #
        #   @option options [Boolean] :allow_unknown_type (false) Suppress errors for
        #     objects of unknown type
        #
        # @return [Git::CommandLineResult] the result of calling `git cat-file --batch-check`
        #
        # @raise [ArgumentError] when `objects` is empty and `batch_all_objects` is not set
        #
        # @raise [Git::FailedError] if git exits with a non-zero status
        #
        def call(*, **)
          bound = args_definition.bind(*, **)
          with_stdin(stdin_content(bound.objects)) { |reader| run_batch(bound, reader) }
        end

        private

        def stdin_content(objects)
          Array(objects).map { |object| "#{object}\n" }.join
        end

        # Executes the bound command with stdin connected to reader
        #
        # @param bound [Git::Commands::Arguments::Bound] bound argument list
        #
        # @param reader [IO] read end of the stdin pipe
        #
        # @return [Git::CommandLineResult]
        #
        def run_batch(bound, reader)
          result = @execution_context.command(
            *bound, in: reader, **bound.execution_options, raise_on_failure: false
          )
          validate_exit_status!(result)
          result
        end
      end
    end
  end
end
