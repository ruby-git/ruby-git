# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Remove a single config entry
      #
      # Wraps `git config --unset` to remove the entry matching the given
      # key name and optional value regex.
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      # @example Unset a config key
      #   Git::Commands::ConfigOptionSyntax::Unset.new(ctx).call('user.name')
      #
      # @example Unset a global config key
      #   Git::Commands::ConfigOptionSyntax::Unset.new(ctx).call('user.name', global: true)
      #
      class Unset < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--unset'

          # File-scope options
          flag_option :global
          flag_option :system
          flag_option :local
          flag_option :worktree
          value_option %i[file f]
          value_option :blob

          # Operands
          end_of_options
          operand :name, required: true
          operand :value_regex
        end

        # git config --unset exits 5 when trying to unset a non-existent or multi-valued key
        allow_exit_status 0..5

        # @!method call(*, **)
        #
        #   @overload call(name, value_regex = nil, **options)
        #
        #     Execute the `git config --unset` command
        #
        #     @param name [String] the config key name to unset
        #
        #     @param value_regex [String, nil] (nil) optional regex to match the value to remove
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :global (nil) remove from global config (`~/.gitconfig`)
        #
        #     @option options [Boolean] :system (nil) remove from system config
        #
        #     @option options [Boolean] :local (nil) remove from repository config (`.git/config`)
        #
        #     @option options [Boolean] :worktree (nil) remove from worktree config
        #
        #     @option options [String] :file (nil) remove from the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --unset`
        #
        #     @raise [Git::FailedError] if git exits outside the allowed status range (0..5)
      end
    end
  end
end
