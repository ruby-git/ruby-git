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
      #   cmd = Git::Commands::ConfigOptionSyntax::List.new(lib)
      #   cmd.call
      #
      # @example List global config entries
      #   cmd = Git::Commands::ConfigOptionSyntax::List.new(lib)
      #   cmd.call(global: true)
      #
      # @example List entries from a specific file
      #   cmd = Git::Commands::ConfigOptionSyntax::List.new(lib)
      #   cmd.call(file: '/path/to/config')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config
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

          # Type constraint
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
        #     @option options [Boolean] :global (false) list only global config entries
        #
        #     @option options [Boolean] :system (false) list only system config entries
        #
        #     @option options [Boolean] :local (false) list only repository config entries
        #
        #     @option options [Boolean] :worktree (false) list only worktree config entries
        #
        #     @option options [String] :file (nil) list entries from the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) list entries from the specified blob
        #
        #     @option options [Boolean] :includes (false) respect include directives in config files
        #       (`--includes`)
        #
        #     @option options [Boolean] :no_includes (false) suppress include directive processing
        #       (`--no-includes`)
        #
        #     @option options [Boolean] :show_origin (false) show the origin of each config entry
        #
        #     @option options [Boolean] :show_scope (false) show the scope of each config entry
        #
        #     @option options [Boolean] :null (false) terminate values with NUL byte instead of newline
        #
        #       Alias: :z
        #
        #     @option options [Boolean] :name_only (false) output only the names of config keys
        #
        #     @option options [String] :type (nil) ensure values conform to the given type
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --list`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
