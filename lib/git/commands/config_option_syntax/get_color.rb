# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Retrieve an ANSI color string from config
      #
      # Wraps `git config --get-color` to look up a color configuration
      # and output the ANSI escape sequence for that color.
      #
      # @example Get a color config value
      #   Git::Commands::ConfigOptionSyntax::GetColor.new(ctx).call('color.diff.new')
      #
      # @example Get a color config value with a default
      #   Git::Commands::ConfigOptionSyntax::GetColor.new(ctx).call('color.diff.new', 'green')
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      class GetColor < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--get-color'

          # File-scope options
          flag_option :global
          flag_option :system
          flag_option :local
          flag_option :worktree
          value_option %i[file f]
          value_option :blob

          # General read options
          flag_option :includes, negatable: true

          # Operands
          end_of_options
          operand :name, required: true
          operand :default
        end

        # @!method call(*, **)
        #
        #   @overload call(name, default = nil, **options)
        #
        #     Execute the `git config --get-color` command
        #
        #     @param name [String] the color config key name to look up
        #
        #     @param default [String, nil] (nil) fallback color when the key is not set
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
        #     @return [Git::CommandLineResult] the result of calling `git config --get-color`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
