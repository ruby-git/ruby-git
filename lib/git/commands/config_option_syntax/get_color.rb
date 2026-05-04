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
      #   cmd = Git::Commands::ConfigOptionSyntax::GetColor.new(lib)
      #   cmd.call('color.diff.new')
      #
      # @example Get a color config value with a default
      #   cmd = Git::Commands::ConfigOptionSyntax::GetColor.new(lib)
      #   cmd.call('color.diff.new', 'green')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config documentation
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
        #     @option options [Boolean] :global (false) read from global config (`~/.gitconfig`)
        #
        #     @option options [Boolean] :system (false) read from system config
        #
        #     @option options [Boolean] :local (false) read from repository config (`.git/config`)
        #
        #     @option options [Boolean] :worktree (false) read from worktree config
        #
        #     @option options [String] :file (nil) read from the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @option options [Boolean] :includes (false) respect include directives in config files
        #       (`--includes`)
        #
        #     @option options [Boolean] :no_includes (false) suppress include directive processing
        #       (`--no-includes`)
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --get-color`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
