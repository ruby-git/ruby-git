# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Retrieve a single config value by exact key name
      #
      # Wraps `git config --get` to return the value of the last-matching
      # config entry for the given key name.
      #
      # @example Get a local config value
      #   cmd = Git::Commands::ConfigOptionSyntax::Get.new(lib)
      #   cmd.call('user.name')
      #
      # @example Get a global config value
      #   cmd = Git::Commands::ConfigOptionSyntax::Get.new(lib)
      #   cmd.call('user.name', global: true)
      #
      # @example Get a value with a type constraint
      #   cmd = Git::Commands::ConfigOptionSyntax::Get.new(lib)
      #   cmd.call('core.bare', type: 'bool')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config documentation
      #
      # @api private
      class Get < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--get'

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
          value_option :default

          # Operands
          end_of_options
          operand :name, required: true
          operand :value_regex
        end

        # git config --get exits 1 when the key is not found (not an error)
        allow_exit_status 0..1

        # @!method call(*, **)
        #
        #   @overload call(name, value_regex = nil, **options)
        #
        #     Execute the `git config --get` command
        #
        #     @param name [String] the config key name to look up
        #
        #     @param value_regex [String, nil] (nil) optional regex to filter the value
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
        #     @option options [Boolean] :includes (false) respect include directives in config files (`--includes`)
        #
        #     @option options [Boolean] :no_includes (false) do not respect include directives
        #       in config files (`--no-includes`)
        #
        #     @option options [String] :type (nil) ensure the value conforms to the given type
        #
        #     @option options [Boolean] :show_origin (nil) show the origin of the config value
        #
        #     @option options [Boolean] :show_scope (nil) show the scope of the config value
        #
        #     @option options [Boolean] :null (nil) terminate values with NUL byte instead of newline
        #
        #       Alias: :z
        #
        #     @option options [String] :default (nil) default value when the key is not found
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --get`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits outside the allowed status range (0..1)
      end
    end
  end
end
