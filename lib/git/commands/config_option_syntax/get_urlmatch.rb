# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Retrieve config values matching a URL
      #
      # Wraps `git config --get-urlmatch` to return config entries whose
      # key name matches the given name and whose URL pattern matches the
      # given URL.
      #
      # @example Get URL-matched config
      #   Git::Commands::ConfigOptionSyntax::GetUrlmatch.new(ctx).call('http', 'https://example.com')
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      class GetUrlmatch < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--get-urlmatch'

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

          # Output modifier
          flag_option %i[null z]

          # Operands
          end_of_options
          operand :name, required: true
          operand :url, required: true
        end

        # git config --get-urlmatch exits 1 when no match is found (not an error)
        allow_exit_status 0..1

        # @!method call(*, **)
        #
        #   @overload call(name, url, **options)
        #
        #     Execute the `git config --get-urlmatch` command
        #
        #     @param name [String] the config key name (or section prefix) to look up
        #
        #     @param url [String] the URL to match against
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
        #     @option options [Boolean] :null (nil) terminate values with NUL byte instead of newline
        #
        #       Alias: :z
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --get-urlmatch`
        #
        #     @raise [Git::FailedError] if git exits outside the allowed status range (0..1)
      end
    end
  end
end
