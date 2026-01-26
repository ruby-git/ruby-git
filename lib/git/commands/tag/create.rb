# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Tag
      # Implements the `git tag` command for creating new tags
      #
      # This command creates a new tag reference pointing at the current HEAD
      # or a specified commit/object.
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      # @example Create a lightweight tag
      #   create = Git::Commands::Tag::Create.new(execution_context)
      #   create.call('v1.0.0')
      #
      # @example Create an annotated tag
      #   create = Git::Commands::Tag::Create.new(execution_context)
      #   create.call('v1.0.0', message: 'Release version 1.0.0')
      #
      # @example Create a signed tag at a specific commit
      #   create = Git::Commands::Tag::Create.new(execution_context)
      #   create.call('v1.0.0', 'abc123', sign: true, message: 'Signed release')
      #
      # @example Force replace an existing tag
      #   create = Git::Commands::Tag::Create.new(execution_context)
      #   create.call('v1.0.0', force: true)
      #
      class Create
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          static 'tag'
          flag %i[annotate a], args: '-a'
          flag %i[sign s], args: '-s'
          flag :no_sign
          inline_value %i[local_user u]
          flag %i[force f], args: '-f'
          flag :create_reflog
          inline_value %i[message m]
          inline_value %i[file F]
          positional :tag_name, required: true
          positional :commit
        end.freeze

        # Initialize the Create command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git tag command to create a new tag
        #
        # @overload call(tag_name, commit = nil, **options)
        #
        #   @param tag_name [String] The name of the tag to create. Must pass all checks
        #     defined by git-check-ref-format.
        #
        #   @param commit [String, nil] The commit, branch, or object to tag.
        #     If omitted, defaults to HEAD.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :annotate (nil) Create an unsigned, annotated tag object.
        #     Requires a message via `:message` or `:file`. Alias: `:a`
        #
        #   @option options [Boolean] :sign (nil) Create a GPG-signed tag using the default
        #     signing key. Requires a message via `:message` or `:file`. Alias: `:s`
        #
        #   @option options [Boolean] :no_sign (nil) Override `tag.gpgSign` configuration
        #     variable that is set to force each and every tag to be signed.
        #
        #   @option options [String] :local_user (nil) Create a GPG-signed tag using the
        #     specified key. Requires a message via `:message` or `:file`. Alias: `:u`
        #
        #   @option options [Boolean] :force (nil) Replace an existing tag with the given
        #     name (instead of failing). Alias: `:f`
        #
        #   @option options [Boolean] :create_reflog (nil) Create a reflog for the tag,
        #     enabling date-based sha1 expressions such as `tag@{yesterday}`.
        #
        #   @option options [String] :message (nil) Use the given message as the tag message.
        #     Implies `-a` if none of `-a`, `-s`, or `-u` is given. Alias: `:m`
        #
        #   @option options [String] :file (nil) Take the tag message from the given file.
        #     Use `-` to read from standard input.
        #     Implies `-a` if none of `-a`, `-s`, or `-u` is given. Alias: `:F`
        #
        # @return [String] the command output
        #
        # @raise [ArgumentError] if creating an annotated tag without a message
        #
        # @raise [Git::FailedError] if the tag already exists (without force)
        #
        def call(*, **)
          validate_options!(**)
          command_args = ARGS.build(*, **)
          @execution_context.command(*command_args)
        end

        private

        # Validate options before executing the command
        #
        # This prevents git from trying to open an editor for the tag message,
        # which would fail in non-interactive mode or block in interactive mode.
        #
        # @param options [Hash] the parsed options
        #
        # @raise [ArgumentError] if an annotated tag is requested without a message
        #
        # @return [void]
        #
        def validate_options!(**options)
          return unless annotated_tag?(options)
          return if message?(options)

          raise ArgumentError, 'Cannot create an annotated tag without a message.'
        end

        # Check if an annotated tag is being requested
        #
        # @param options [Hash] the parsed options
        # @return [Boolean]
        #
        def annotated_tag?(options)
          options[:annotate] || options[:a] || options[:sign] || options[:s] ||
            options[:local_user] || options[:u]
        end

        # Check if a message is provided for the tag
        #
        # Empty strings are not considered valid messages since ARGS.build will
        # drop them (allow_empty: false is the default), which would cause git
        # to open an editor unexpectedly.
        #
        # @param options [Hash] the parsed options
        # @return [Boolean]
        #
        def message?(options)
          [
            options[:message],
            options[:m],
            options[:file],
            options[:F]
          ].compact.any? { |value| value != '' }
        end
      end
    end
  end
end
