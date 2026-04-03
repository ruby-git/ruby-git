# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # List all config entries
      #
      # Wraps `git config --list` to output all config entries visible
      # from the current scope.
      #
      # @example List all config entries
      #   Git::Commands::ConfigOptionSyntax::List.new(ctx).call
      #
      # @example List global config entries
      #   Git::Commands::ConfigOptionSyntax::List.new(ctx).call(global: true)
      #
      # @example List entries from a specific file
      #   Git::Commands::ConfigOptionSyntax::List.new(ctx).call(file: '/path/to/config')
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      class List < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--list'

          # File-scope options
          flag_option :global
          flag_option :system
          flag_option :local
          flag_option :worktree
          value_option %i[file f]
          value_option :blob

          # General read options
          flag_option :includes, negatable: true

          # Output modifiers
          flag_option :show_origin
          flag_option :show_scope
          flag_option %i[null z]
          flag_option :name_only

          # Type constraint (not in --list SYNOPSIS but accepted in practice)
          value_option :type, inline: true
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Execute the `git config --list` command
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :global (nil) list only global config entries
        #
        #     @option options [Boolean] :system (nil) list only system config entries
        #
        #     @option options [Boolean] :local (nil) list only repository config entries
        #
        #     @option options [Boolean] :worktree (nil) list only worktree config entries
        #
        #     @option options [String] :file (nil) list entries from the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) list entries from the specified blob
        #
        #     @option options [Boolean] :includes (nil) respect include directives in config files
        #
        #     @option options [Boolean] :show_origin (nil) show the origin of each config entry
        #
        #     @option options [Boolean] :show_scope (nil) show the scope of each config entry
        #
        #     @option options [Boolean] :null (nil) terminate values with NUL byte instead of newline
        #
        #       Alias: :z
        #
        #     @option options [Boolean] :name_only (nil) output only the names of config keys
        #
        #     @option options [String] :type (nil) ensure values conform to the given type
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --list`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
