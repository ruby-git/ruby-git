# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Remove a config section
      #
      # Wraps `git config --remove-section` to remove an entire section
      # from the config file.
      #
      # @example Remove a section
      #   Git::Commands::ConfigOptionSyntax::RemoveSection.new(ctx).call('old-section')
      #
      # @see https://git-scm.com/docs/git-config/2.28.0 git-config documentation (v2.28.0)
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @api private
      #
      class RemoveSection < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--remove-section'

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
        end

        # @!method call(*, **)
        #
        #   @overload call(name, **options)
        #
        #     Execute the `git config --remove-section` command
        #
        #     @param name [String] the section name to remove
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :global (nil) operate on global config (`~/.gitconfig`)
        #
        #     @option options [Boolean] :system (nil) operate on system config
        #
        #     @option options [Boolean] :local (nil) operate on repository config (`.git/config`)
        #
        #     @option options [Boolean] :worktree (nil) operate on worktree config
        #
        #     @option options [String] :file (nil) operate on the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --remove-section`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
