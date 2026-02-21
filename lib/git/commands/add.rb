# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git add` command
    #
    # This command updates the index using the current content found in the working tree,
    # to prepare the content staged for the next commit.
    #
    # @api private
    #
    # @example Basic usage
    #   add = Git::Commands::Add.new(execution_context)
    #   add.call('path/to/file')
    #   add.call('file1.rb', 'file2.rb')
    #   add.call(all: true)
    #
    class Add < Git::Commands::Base
      arguments do
        literal 'add'
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
        flag_option :no_warn_embedded_repo
        flag_option :renormalize
        value_option :chmod, inline: true
        value_option :pathspec_from_file, inline: true
        flag_option :pathspec_file_nul
        operand :pathspec, repeatable: true, separator: '--'

        allowed_values :chmod, in: ['+x', '-x']
        conflicts :all, :update
        conflicts :ignore_removal, :update
        conflicts :pathspec, :pathspec_from_file
        # --all=true  + --ignore-removal=true  : contradictory (stage all vs ignore removed files)
        # --all=false + --ignore-removal=false : contradictory (--no-all vs --no-ignore-removal cancel out)
        # Equivalent pairs (--no-all --ignore-removal or --all --no-ignore-removal) are allowed.
        forbid_values all: true,  ignore_removal: true
        forbid_values all: false, ignore_removal: false
        requires :pathspec_from_file, when: :pathspec_file_nul
        requires :dry_run, when: :ignore_missing
      end

      # @!method call(*, **)
      #
      #   @overload call(*pathspec, **options)
      #
      #     Execute the git add command.
      #
      #     @param pathspec [Array<String>] files to be added to the repository
      #       (relative to the worktree root)
      #
      #     @option options [Boolean] :dry_run (nil) Don't actually add files; show what would be added.
      #       Alias: :n
      #
      #     @option options [Boolean] :force (nil) Allow adding otherwise ignored files.
      #       Alias: :f
      #
      #     @option options [Boolean] :all (nil) Add, modify, and remove index entries to match the worktree.
      #       Use `no_all: true` (i.e. `--no-all`) to ignore removed files. Alias: :A.
      #       Mutually exclusive with :update.
      #
      #     @option options [Boolean] :update (nil) Update tracked files only; does not add new files.
      #       Mutually exclusive with :all and :ignore_removal. Alias: :u
      #
      #     @option options [Boolean] :ignore_removal (nil) Add and modify files, but ignore removed files.
      #       Use `ignore_removal: false` (i.e. `--no-ignore-removal`) to match :all behavior.
      #       Mutually exclusive with :update.
      #
      #     @option options [Boolean] :sparse (nil) Allow updating index entries outside the
      #       sparse-checkout cone.
      #
      #     @option options [Boolean] :intent_to_add (nil) Record that the path will be added later,
      #       placing an empty entry in the index. Alias: :N
      #
      #     @option options [Boolean] :refresh (nil) Refresh stat() information in the index without
      #       adding files.
      #
      #     @option options [Boolean] :ignore_errors (nil) Continue adding other files if some files
      #       cannot be added due to indexing errors.
      #
      #     @option options [Boolean] :ignore_missing (nil) Check whether any given files would be
      #       ignored. Only meaningful with :dry_run.
      #
      #     @option options [Boolean] :no_warn_embedded_repo (nil) Suppress warning when adding an
      #       embedded repository without using `git submodule add`.
      #
      #     @option options [Boolean] :renormalize (nil) Apply the clean process freshly to all tracked
      #       files to forcibly re-add them with correct line endings.
      #
      #     @option options [String] :chmod (nil) Override the executable bit of added files in the
      #       index. Value must be `'+x'` or `'-x'`.
      #
      #     @option options [String] :pathspec_from_file (nil) Read pathspec from the given file
      #       (use `'-'` for stdin).
      #
      #       Mutually exclusive with positional :pathspec values.
      #
      #     @option options [Boolean] :pathspec_file_nul (nil) Separate pathspec elements with NUL
      #       when reading from a file. Only meaningful with :pathspec_from_file.
      #
      #     @return [Git::CommandLineResult] the result of the command
    end
  end
end
