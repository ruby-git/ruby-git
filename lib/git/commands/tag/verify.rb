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
      # @see Git::Commands::Tag
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
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
      class Verify < Base
        arguments do
          literal 'tag'
          literal '--verify'
          value_option :format, inline: true
          operand :tag_names, repeatable: true, required: true
        end

        # Execute the git tag --verify command to verify tag signatures
        #
        # @overload call(*tag_names, **options)
        #
        #   @param tag_names [Array<String>] One or more tag names to verify.
        #     At least one tag name is required.
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :format (nil) A format string that interpolates
        #     `%(fieldname)` from the tag ref being shown and the object it points at.
        #     The format is the same as that of git-for-each-ref.
        #
        # @return [Git::CommandLineResult] the result of calling `git tag --verify`
        #
        # @raise [Git::FailedError] if the tag does not exist or signature verification fails
        #
        # @raise [ArgumentError] if no tag names are provided
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
