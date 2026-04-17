# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module SymbolicRef
      # Creates or updates a symbolic ref via `git symbolic-ref`
      #
      # Given two arguments, creates or updates a symbolic ref `<name>` to
      # point at the given branch `<ref>`.
      #
      # @example Update HEAD to point to a branch
      #   cmd = Git::Commands::SymbolicRef::Update.new(execution_context)
      #   cmd.call('HEAD', 'refs/heads/main')
      #
      # @example Update HEAD with a reflog message
      #   cmd = Git::Commands::SymbolicRef::Update.new(execution_context)
      #   cmd.call('HEAD', 'refs/heads/main', m: 'switching to main')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-symbolic-ref/2.53.0
      #
      # @see Git::Commands::SymbolicRef
      #
      # @see https://git-scm.com/docs/git-symbolic-ref git-symbolic-ref documentation
      #
      # @api private
      #
      class Update < Git::Commands::Base
        arguments do
          literal 'symbolic-ref'

          # Reflog message for the update
          value_option :m

          end_of_options

          # The symbolic ref name to update (e.g. `HEAD`)
          operand :name, required: true

          # The target ref to point to (e.g. `refs/heads/main`)
          operand :ref, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, ref, **options)
        #
        #     Execute the `git symbolic-ref` command to create or update a
        #     symbolic ref
        #
        #     @param name [String] the symbolic ref name to update
        #       (e.g. `HEAD`)
        #
        #     @param ref [String] the target ref to point to
        #       (e.g. `refs/heads/main`)
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :m (nil) a reflog message for
        #       the update
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git symbolic-ref`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [ArgumentError] if the name operand is missing
        #
        #     @raise [ArgumentError] if the ref operand is missing
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
