# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git add` command
    #
    # This command updates the index using the current content found in the working tree,
    # to prepare the content staged for the next commit.
    #
    # @example Basic usage
    #   add = Git::Commands::Add.new(execution_context)
    #   add.call('path/to/file')
    #   add.call('file1.rb', 'file2.rb')
    #   add.call(all: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-add/2.53.0
    #
    # @see https://git-scm.com/docs/git-add git-add
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Add < Git::Commands::Base
      arguments do
        literal 'add'
        flag_option %i[verbose v]
        flag_option %i[dry_run n]
        flag_option %i[force f]
        flag_option %i[all A], negatable: true
        flag_option :ignore_removal, negatable: true
        flag_option %i[update u]
        flag_option :sparse
        flag_option %i[intent_to_add N]
        flag_option :refresh
        flag_option :ignore_errors
        flag_option :ignore_missing
        flag_option :renormalize
        flag_option :no_warn_embedded_repo
        value_option :chmod, inline: true
        value_option :pathspec_from_file, inline: true
        flag_option :pathspec_file_nul
        end_of_options
        operand :pathspec, repeatable: true
      end

      # @overload call(*pathspec, **options)
      #
      #   Execute the `git add` command
      #
      #   @param pathspec [Array<String>] files to be added to the repository
      #     (relative to the worktree root)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean, nil] :verbose (nil) be verbose
      #
      #     Alias: :v
      #
      #   @option options [Boolean, nil] :dry_run (nil) don't actually add files;
      #     show what would be added
      #
      #     Alias: :n
      #
      #   @option options [Boolean, nil] :force (nil) allow adding otherwise ignored
      #     files
      #
      #     Alias: :f
      #
      #   @option options [Boolean, nil] :all (nil) add, modify, and remove index
      #     entries to match the worktree (--all)
      #
      #     Alias: :A
      #
      #   @option options [Boolean, nil] :no_all (nil) add and modify index entries
      #     without staging removals (--no-all)
      #
      #   @option options [Boolean, nil] :ignore_removal (nil) add and modify files;
      #     ignore removals (--ignore-removal)
      #
      #   @option options [Boolean, nil] :no_ignore_removal (nil) include file removals
      #     (--no-ignore-removal)
      #
      #   @option options [Boolean, nil] :update (nil) update tracked files only; does
      #     not add new files
      #
      #     Alias: :u
      #
      #   @option options [Boolean, nil] :sparse (nil) allow updating index entries
      #     outside the sparse-checkout cone
      #
      #   @option options [Boolean, nil] :intent_to_add (nil) record that the path
      #     will be added later, placing an empty entry in the index
      #
      #     Alias: :N
      #
      #   @option options [Boolean, nil] :refresh (nil) refresh stat() information in
      #     the index without adding files
      #
      #   @option options [Boolean, nil] :ignore_errors (nil) continue adding other
      #     files if some files cannot be added due to indexing errors
      #
      #   @option options [Boolean, nil] :ignore_missing (nil) check whether any given
      #     files would be ignored
      #
      #   @option options [Boolean, nil] :renormalize (nil) apply the "clean" process
      #     freshly to all tracked files to forcibly re-add them with correct line
      #     endings
      #
      #   @option options [Boolean, nil] :no_warn_embedded_repo (nil) suppress warning
      #     when adding an embedded repository without using `git submodule add`
      #
      #   @option options [String] :chmod (nil) override the executable bit of added
      #     files in the index
      #
      #     Value must be `'+x'` or `'-x'`
      #
      #   @option options [String] :pathspec_from_file (nil) read pathspec from the
      #     given file (use `'-'` for stdin)
      #
      #   @option options [Boolean, nil] :pathspec_file_nul (nil) separate pathspec
      #     elements with NUL when reading from a file
      #
      #   @return [Git::CommandLineResult] the result of calling `git add`
      #
      #   @raise [ArgumentError] if unsupported options are provided
      #
      #   @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
      #
      def call(*, **)
        super
      end
    end
  end
end
