# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Tag
      # Implements the `git tag --verify` command for verifying tag signatures
      #
      # This command verifies the cryptographic signature of the given tag(s).
      # It requires that the tags were signed with GPG or another supported
      # signing backend.
      #
      # @example Verify a single tag
      #   verify = Git::Commands::Tag::Verify.new(execution_context)
      #   verify.call('v1.0.0')
      #
      # @example Verify multiple tags
      #   verify = Git::Commands::Tag::Verify.new(execution_context)
      #   verify.call('v1.0.0', 'v2.0.0')
      #
      # @example Verify with custom format output
      #   verify = Git::Commands::Tag::Verify.new(execution_context)
      #   verify.call('v1.0.0', format: '%(refname:short) %(contents:subject)')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-tag/2.53.0
      #
      # @see Git::Commands::Tag
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      class Verify < Git::Commands::Base
        arguments do
          literal 'tag'
          literal '--verify'
          value_option :format, inline: true

          end_of_options

          operand :tagname, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   Execute the git tag --verify command to verify tag signatures
        #
        #   @overload call(*tagname, **options)
        #
        #     @param tagname [Array<String>] one or more tag names to verify
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :format (nil) a format string interpolating
        #       `%(fieldname)` from the tag ref being shown and the object it points at
        #
        #       The format is the same as that of git-for-each-ref(1).
        #
        #     @return [Git::CommandLineResult] the result of calling `git tag --verify`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [ArgumentError] if no tagname operands are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
      end
    end
  end
end
