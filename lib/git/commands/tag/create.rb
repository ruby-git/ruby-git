# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Tag
      # Implements the `git tag` command for creating new tags
      #
      # This command creates a new tag reference pointing at the current HEAD
      # or a specified commit/object.
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
      # @note `arguments` block audited against https://git-scm.com/docs/git-tag/2.53.0
      #
      # @see Git::Commands::Tag
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      class Create < Git::Commands::Base
        arguments do
          literal 'tag'
          flag_option %i[annotate a]
          flag_option %i[sign s], negatable: true
          value_option %i[local_user u], inline: true
          flag_option %i[force f]
          value_option %i[message m], inline: true
          value_option %i[file F], inline: true
          flag_option %i[edit e], negatable: true
          key_value_option :trailer, key_separator: ': '
          value_option :cleanup, inline: true
          flag_option :create_reflog

          end_of_options

          operand :tagname, required: true
          operand :commit
        end

        # @!method call(*, **)
        #
        #   Execute the git tag command to create a new tag
        #
        #   @overload call(tagname, commit = nil, **options)
        #
        #     @param tagname [String] the name of the tag to create
        #
        #     @param commit [String, nil] the commit, branch, or object to tag
        #
        #       Defaults to HEAD when omitted.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :annotate (false) make an unsigned, annotated tag object
        #
        #       Requires a message via `:message` or `:file`.
        #
        #       Alias: :a
        #
        #     @option options [Boolean] :sign (false) make a GPG-signed tag using the default signing key (`--sign`)
        #
        #       Requires a message via `:message` or `:file`.
        #
        #       Alias: :s
        #
        #     @option options [Boolean] :no_sign (false) override `tag.gpgSign` config to disable signing (`--no-sign`)
        #
        #     @option options [String] :local_user (nil) make a cryptographically signed tag using the given key
        #
        #       Requires a message via `:message` or `:file`.
        #
        #       Alias: :u
        #
        #     @option options [Boolean] :force (false) replace an existing tag with the given name instead of failing
        #
        #       Alias: :f
        #
        #     @option options [String] :message (nil) use the given message as the tag message
        #
        #       Implies `--annotate` if none of `--annotate`, `--sign`, or `--local-user` is given.
        #
        #       Alias: :m
        #
        #     @option options [String] :file (nil) take the tag message from the given file
        #
        #       Use `-` to read from standard input. Implies `--annotate` if none of
        #       `--annotate`, `--sign`, or `--local-user` is given.
        #
        #       Alias: :F
        #
        #     @option options [Boolean] :edit (false) open an editor to further edit the tag message (`--edit`)
        #
        #       Alias: :e
        #
        #     @option options [Boolean] :no_edit (false) suppress the editor (`--no-edit`)
        #
        #     @option options [Hash, Array<Array>] :trailer (nil) add trailers to the tag message
        #
        #       Can be a Hash `{ 'Key' => 'value' }` or Array of pairs `[['Key', 'value']]`.
        #       Multiple trailers can be specified.
        #
        #     @option options [String] :cleanup (nil) set how the tag message is cleaned up
        #
        #       Must be one of: `verbatim` (no changes), `whitespace` (remove leading/trailing
        #       whitespace lines), or `strip` (remove whitespace and commentary). Default is `strip`.
        #
        #     @option options [Boolean] :create_reflog (false) create a reflog for the tag
        #
        #       Enables date-based sha1 expressions such as `tag@{yesterday}`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git tag`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
      end
    end
  end
end
