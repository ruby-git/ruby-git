# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Wrapper for the `git version` command
    #
    # Prints the git suite version.
    #
    # @example Basic usage
    #   version = Git::Commands::Version.new(execution_context)
    #   result = version.call
    #   result.stdout #=> "git version 2.42.0"
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-version/2.53.0
    #
    # @see Git::Commands
    #
    # @see https://git-scm.com/docs/git-version git-version documentation
    #
    # @api private
    #
    class Version < Git::Commands::Base
      # Skip version validation for this command since this command is used to
      # determine the version.
      #
      skip_version_validation

      arguments do
        literal 'version'
        flag_option :build_options
      end

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Execute the `git version` command.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :build_options (false) include build options in the output
      #
      #     @return [Git::CommandLineResult] the result of calling `git version`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
