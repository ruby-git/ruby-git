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
      # @see Git::Commands::Tag
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
          literal 'tag'
          flag_option %i[annotate a]
          flag_option %i[sign s], negatable: true
          value_option %i[local_user u], inline: true
          flag_option %i[force f]
          flag_option :create_reflog
          value_option %i[message m], inline: true
          value_option %i[file F], inline: true
          key_value_option :trailer, key_separator: ': '
          value_option :cleanup, inline: true
          operand :tag_name, required: true
          operand :commit

          conflicts :annotate, :sign, :local_user
          conflicts :message, :file
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
        #     Requires a message via `:message` or `:file`. Also available as `:a`.
        #
        #   @option options [Boolean] :sign (nil) Create a GPG-signed tag using the default
        #     signing key. Requires a message via `:message` or `:file`. Set to `false` to
        #     override `tag.gpgSign` config. Also available as `:s`.
        #
        #   @option options [String] :local_user (nil) Create a GPG-signed tag using the
        #     specified key. Requires a message via `:message` or `:file`. Also available as `:u`.
        #
        #   @option options [Boolean] :force (nil) Replace an existing tag with the given
        #     name (instead of failing). Also available as `:f`.
        #
        #   @option options [Boolean] :create_reflog (nil) Create a reflog for the tag,
        #     enabling date-based sha1 expressions such as `tag@{yesterday}`.
        #
        #   @option options [String] :message (nil) Use the given message as the tag message.
        #     Implies `-a` if none of `-a`, `-s`, or `-u` is given. Also available as `:m`.
        #
        #   @option options [String] :file (nil) Take the tag message from the given file.
        #     Use `-` to read from standard input. Implies `-a` if none of `-a`, `-s`, or `-u`
        #     is given. Also available as `:F`.
        #
        #   @option options [Hash, Array<Array>] :trailer (nil) Add trailers to the tag message.
        #     Can be a Hash `{ 'Key' => 'value' }` or Array of pairs `[['Key', 'value']]`.
        #     Multiple trailers can be specified.
        #
        #   @option options [String] :cleanup (nil) Set how the tag message is cleaned up.
        #     Must be one of: `verbatim` (no changes), `whitespace` (remove leading/trailing
        #     whitespace lines), or `strip` (remove whitespace and commentary). Default is `strip`.
        #
        # @return [Git::CommandLineResult] the result of calling `git tag`
        #
        # @raise [Git::FailedError] if the tag already exists (without force) or if
        #   an annotated tag is requested without a message
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)

          @execution_context.command(*bound_args)
        end
      end
    end
  end
end
