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
      # @example Set a local config value
      #   cmd = Git::Commands::ConfigOptionSyntax::Set.new(lib)
      #   cmd.call('user.name', 'Alice')
      #
      # @example Set a global config value
      #   cmd = Git::Commands::ConfigOptionSyntax::Set.new(lib)
      #   cmd.call('user.name', 'Alice', global: true)
      #
      # @example Set a value with a type constraint
      #   cmd = Git::Commands::ConfigOptionSyntax::Set.new(lib)
      #   cmd.call('core.bare', 'true', type: 'bool')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config documentation
      #
      # @api private
      #
      class Set < Git::Commands::Base
        arguments do
          literal 'config'

          # Write modifiers
          flag_option :replace_all
          flag_option :append
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
        #     @option options [Boolean] :replace_all (false) replace all lines matching the key
        #
        #     @option options [Boolean] :append (false) add a new line without altering existing values
        #
        #     @option options [String] :comment (nil) append a comment at the end of new or modified lines
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
        #     @option options [Boolean] :fixed_value (false) treat the value regex as an exact string
        #
        #     @option options [String] :type (nil) ensure the value conforms to the given type
        #
        #     @option options [Boolean] :no_type (false) unset the previously set type specifier;
        #       `true` emits `--no-type`
        #
        #     @return [Git::CommandLineResult] the result of calling `git config`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
