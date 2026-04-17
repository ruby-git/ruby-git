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
      #   cmd = Git::Commands::ConfigOptionSyntax::RemoveSection.new(lib)
      #   cmd.call('old-section')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config
      #
      # @api private
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
        #     @option options [Boolean] :global (false) remove from global config (`~/.gitconfig`)
        #
        #     @option options [Boolean] :system (false) remove from system config
        #
        #     @option options [Boolean] :local (false) remove from repository config (`.git/config`)
        #
        #     @option options [Boolean] :worktree (false) remove from worktree config
        #
        #     @option options [String] :file (nil) remove from the specified file
        #
        #       Alias: :f
        #
        #     @option options [String] :blob (nil) read from the specified blob
        #
        #     @return [Git::CommandLineResult] the result of calling `git config --remove-section`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
