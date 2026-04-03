# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Replace all matching values for a config key
      #
      # Wraps `git config --replace-all` to replace all entries matching the
      # given key and optional value regex with a new value.
      #
      # @example Replace all values for a key
      #   Git::Commands::ConfigOptionSyntax::ReplaceAll.new(ctx).call('core.autocrlf', 'true')
      #
      # @example Replace values matching a pattern
      #   Git::Commands::ConfigOptionSyntax::ReplaceAll.new(ctx).call('core.autocrlf', 'true', 'false')
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      class ReplaceAll < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--replace-all'

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
        #     Execute the `git config --replace-all` command
        #
        #     @param name [String] the config key name
        #
        #     @param value [String] the new value to set
        #
        #     @param value_regex [String, nil] (nil) optional regex to match existing values to replace
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
        #     @return [Git::CommandLineResult] the result of calling `git config --replace-all`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
