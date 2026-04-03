# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Set a config value
      #
      # Wraps the implicit `git config <name> <value>` set mode to assign
      # a value to a config key, optionally replacing only the entry
      # matching a value regex.
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      # @example Set a local config value
      #   Git::Commands::ConfigOptionSyntax::Set.new(ctx).call('user.name', 'Alice')
      #
      # @example Set a global config value
      #   Git::Commands::ConfigOptionSyntax::Set.new(ctx).call('user.name', 'Alice', global: true)
      #
      # @example Set a value with a type constraint
      #   Git::Commands::ConfigOptionSyntax::Set.new(ctx).call('core.bare', 'true', type: 'bool')
      #
      class Set < Git::Commands::Base
        arguments do
          literal 'config'

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
          operand :value_regex
        end

        # @!method call(*, **)
        #
        #   @overload call(name, value, value_regex = nil, **options)
        #
        #     Execute the `git config <name> <value>` command
        #
        #     @param name [String] the config key name to set
        #
        #     @param value [String] the value to assign
        #
        #     @param value_regex [String, nil] (nil) optional regex to match the existing value to replace
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
        #     @return [Git::CommandLineResult] the result of calling `git config`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
