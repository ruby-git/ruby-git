# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Retrieve all values for a multi-valued config key
      #
      # Wraps `git config --get-all` to return all values matching the given
      # key name, one per line.
      #
      # @example Get all values for a key
      #   Git::Commands::ConfigOptionSyntax::GetAll.new(ctx).call('remote.origin.fetch')
      #
      # @example Get all values with a value pattern
      #   Git::Commands::ConfigOptionSyntax::GetAll.new(ctx).call('remote.origin.fetch', '\\+refs/heads/.*')
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      class GetAll < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--get-all'

          # File-scope options
          flag_option :global
          flag_option :system
          flag_option :local
          flag_option :worktree
          value_option %i[file f]
          value_option :blob

          # General read options
          flag_option :includes, negatable: true

          # Type constraint
          value_option :type, inline: true

          # Output modifiers
          flag_option :show_origin
          flag_option :show_scope
          flag_option %i[null z]

          # Operands
          end_of_options
          operand :name, required: true
          operand :value_regex
        end

        # git config --get-all exits 1 when the key is not found (not an error)
        allow_exit_status 0..1

        # @!method call(*, **)
        #
        #   @overload call(name, value_regex = nil, **options)
        #
        #     Execute the `git config --get-all` command
        #
        #     @param name [String] the config key name to look up
        #
        #     @param value_regex [String, nil] optional regex to filter values
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :global (nil) read from global config (`~/.gitconfig`)
        #
        #     @option options [Boolean] :system (nil) read from system config
        #
        #     @option options [Boolean] :local (nil) read from repository config (`.git/config`)
        #
        #     @option options [Boolean] :worktree (nil) read from worktree config
        #
        #     @option options [String] :file (nil) read from the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @option options [Boolean] :includes (nil) respect include directives in config files
        #
        #     @option options [String] :type (nil) ensure values conform to the given type
        #
        #     @option options [Boolean] :show_origin (nil) show the origin of each config value
        #
        #     @option options [Boolean] :show_scope (nil) show the scope of each config value
        #
        #     @option options [Boolean] :null (nil) terminate values with NUL byte instead of newline
        #
        #       Alias: :z
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --get-all`
        #
        #     @raise [Git::FailedError] if git exits outside the allowed status range (0..1)
      end
    end
  end
end
