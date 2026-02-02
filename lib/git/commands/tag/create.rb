# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/tag/list'

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
          value %i[local_user u], inline: true
          flag %i[force f], args: '-f'
          flag :create_reflog
          value %i[message m], inline: true
          value %i[file F], inline: true
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
        # @return [Git::TagInfo] the info for the tag that was created
        #
        # @raise [Git::FailedError] if the tag already exists (without force) or if
        #   an annotated tag is requested without a message
        #
        def call(*args, **)
          command_args = ARGS.build(*args, **)
          @execution_context.command(*command_args)

          # Get tag info for the newly created tag
          tag_name = args[0]
          Git::Commands::Tag::List.new(@execution_context).call(tag_name).first
        end
      end
    end
  end
end
