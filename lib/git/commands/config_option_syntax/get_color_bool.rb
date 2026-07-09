# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Query whether color output is enabled for a config key
      #
      # Wraps `git config --get-colorbool` to check whether color output
      # should be used. This command has no subcommand equivalent even in
      # git 2.46.0 — it exists only in the option-syntax interface.
      #
      # @example Query whether color is enabled for diff
      #   cmd = Git::Commands::ConfigOptionSyntax::GetColorBool.new(lib)
      #   cmd.call('color.diff')
      #
      # @example Query with explicit stdout-is-tty hint
      #   cmd = Git::Commands::ConfigOptionSyntax::GetColorBool.new(lib)
      #   cmd.call('color.diff', 'true')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config documentation
      #
      # @api private
      #
      class GetColorBool < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--get-colorbool'

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
          operand :stdout_is_tty
        end

        # git config --get-colorbool exits 0 for color=yes, 1 for color=no
        allow_exit_status 0..1

        # @overload call(name, stdout_is_tty = nil, **options)
        #
        #     Execute the `git config --get-colorbool` command
        #
        #     @param name [String] the color config key name to query
        #
        #     @param stdout_is_tty [String, nil] (nil) hint whether stdout is a TTY (`"true"` or `"false"`)
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, nil] :global (nil) read from global config (`~/.gitconfig`)
        #
        #     @option options [Boolean, nil] :system (nil) read from system config
        #
        #     @option options [Boolean, nil] :local (nil) read from repository config (`.git/config`)
        #
        #     @option options [Boolean, nil] :worktree (nil) read from worktree config
        #
        #     @option options [String] :file (nil) read from the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @option options [Boolean, nil] :includes (nil) respect include directives in config files (`--includes`)
        #
        #     @option options [Boolean, nil] :no_includes (nil) disable include directive processing (`--no-includes`)
        #
        #     @return [Git::CommandLine::Result] the result of calling `git config --get-colorbool`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
        #
        #     @api public
        def call(*, **)
          super
        end
      end
    end
  end
end
