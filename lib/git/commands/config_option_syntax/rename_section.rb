# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module ConfigOptionSyntax
      # Rename a config section
      #
      # Wraps `git config --rename-section` to rename a section in the
      # config file.
      #
      # @example Rename a section
      #   cmd = Git::Commands::ConfigOptionSyntax::RenameSection.new(lib)
      #   cmd.call('old-section', 'new-section')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-config/2.53.0
      #
      # @see Git::Commands::ConfigOptionSyntax
      #
      # @see https://git-scm.com/docs/git-config git-config
      #
      # @api private
      #
      class RenameSection < Git::Commands::Base
        arguments do
          literal 'config'
          literal '--rename-section'

          # File-scope options
          flag_option :global
          flag_option :system
          flag_option :local
          flag_option :worktree
          value_option %i[file f]
          value_option :blob

          # Operands
          end_of_options
          operand :old_name, required: true
          operand :new_name, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(old_name, new_name, **options)
        #
        #     Execute the `git config --rename-section` command
        #
        #     @param old_name [String] the current section name
        #
        #     @param new_name [String] the new section name
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
        #     @return [Git::CommandLineResult] the result of calling `git config --rename-section`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
