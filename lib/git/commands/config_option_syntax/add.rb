# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Append a value to a multi-valued config key
      #
      # Wraps `git config --add` to add a new line to a config key without
      # altering existing values.
      #
      # @example Add a value to a multi-valued key
      #   Git::Commands::ConfigOptionSyntax::Add.new(ctx).call(
      #     'remote.origin.fetch', '+refs/heads/*:refs/remotes/origin/*'
      #   )
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      class Add < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--add'

          # File-scope options
          flag_option :global
          flag_option :system
          flag_option :local
          flag_option :worktree
          value_option %i[file f]
          value_option :blob

          # Type constraint
          value_option :type, inline: true

          # Operands
          end_of_options
          operand :name, required: true
          operand :value, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, value, **options)
        #
        #     Execute the `git config --add` command
        #
        #     @param name [String] the config key name
        #
        #     @param value [String] the value to append
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :global (nil) write to global config (`~/.gitconfig`)
        #
        #     @option options [Boolean] :system (nil) write to system config
        #
        #     @option options [Boolean] :local (nil) write to repository config (`.git/config`)
        #
        #     @option options [Boolean] :worktree (nil) write to worktree config
        #
        #     @option options [String] :file (nil) write to the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @option options [String] :type (nil) ensure the value conforms to the given type
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --add`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
