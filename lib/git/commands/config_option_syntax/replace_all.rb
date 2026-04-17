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
      #   cmd = Git::Commands::ConfigOptionSyntax::ReplaceAll.new(lib)
      #   cmd.call('core.autocrlf', 'true')
      #
      # @example Replace values matching a pattern
      #   cmd = Git::Commands::ConfigOptionSyntax::ReplaceAll.new(lib)
      #   cmd.call('core.autocrlf', 'true', 'false')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config documentation
      #
      # @api private
      #
      class ReplaceAll < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--replace-all'

          # Write modifiers
          value_option :comment

          # File-scope options
          flag_option :global
          flag_option :system
          flag_option :local
          flag_option :worktree
          value_option %i[file f]
          value_option :blob

          # Value matching
          flag_option :fixed_value

          # Type constraint
          value_option :type, inline: true
          flag_option :no_type

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
        #     @option options [Boolean] :global (false) write to global config (`~/.gitconfig`)
        #
        #     @option options [Boolean] :system (false) write to system config
        #
        #     @option options [Boolean] :local (false) write to repository config (`.git/config`)
        #
        #     @option options [Boolean] :worktree (false) write to worktree config
        #
        #     @option options [String] :file (nil) write to the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @option options [String] :comment (nil) append a comment at the end of new or modified lines
        #
        #     @option options [Boolean] :fixed_value (false) treat the value regex as an exact string
        #
        #     @option options [String] :type (nil) ensure the value conforms to the given type
        #
        #     @option options [Boolean] :no_type (false) unset the previously set type specifier;
        #       `true` emits `--no-type`
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --replace-all`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
