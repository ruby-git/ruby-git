# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git rev-parse` command
    #
    # Picks out and massages parameters for other git commands. Most commonly
    # used to resolve a revision specifier (branch name, tag, abbreviated SHA)
    # to its full object name. Also provides repository metadata queries and
    # argument classification for porcelain scripts.
    #
    # The `--parseopt` and `--sq-quote` operation modes are excluded because
    # they require stdin interaction or provide no value in a Ruby library.
    #
    # @example Resolve HEAD to its full SHA
    #   rev_parse = Git::Commands::RevParse.new(execution_context)
    #   result = rev_parse.call('HEAD', verify: true)
    #
    # @example Query the repository top-level directory
    #   rev_parse = Git::Commands::RevParse.new(execution_context)
    #   result = rev_parse.call(show_toplevel: true)
    #
    # @example List all branch refs
    #   rev_parse = Git::Commands::RevParse.new(execution_context)
    #   result = rev_parse.call(branches: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-rev-parse/2.53.0
    #
    # @see https://git-scm.com/docs/git-rev-parse git-rev-parse
    #
    # @api private
    #
    class RevParse < Git::Commands::Base
      arguments do
        literal 'rev-parse'

        # Filtering
        flag_option :revs_only
        flag_option :no_revs
        flag_option :flags, negatable: true

        # Output
        value_option :default
        value_option :prefix
        flag_option :verify
        flag_option %i[quiet q]
        flag_option :sq
        flag_or_value_option :short, inline: true
        flag_option :not
        flag_or_value_option :abbrev_ref, inline: true
        flag_option :symbolic
        flag_option :symbolic_full_name
        value_option :output_object_format, inline: true

        # Objects
        flag_option :all
        flag_or_value_option :branches, inline: true
        flag_or_value_option :tags, inline: true
        flag_or_value_option :remotes, inline: true
        value_option :glob, inline: true
        value_option :exclude, inline: true, repeatable: true
        value_option :exclude_hidden, inline: true
        value_option :disambiguate, inline: true

        # Files
        flag_option :local_env_vars
        value_option :path_format, inline: true, repeatable: true
        flag_option :git_dir
        flag_option :absolute_git_dir
        flag_option :git_common_dir
        flag_option :is_inside_git_dir
        flag_option :is_inside_work_tree
        flag_option :is_bare_repository
        flag_option :is_shallow_repository
        value_option :resolve_git_dir
        value_option :git_path
        flag_option :show_cdup
        flag_option :show_prefix
        flag_option :show_toplevel
        flag_option :show_superproject_working_tree
        flag_option :shared_index_path
        flag_or_value_option :show_object_format, inline: true
        flag_option :show_ref_format

        # Date conversion
        value_option %i[since after], inline: true
        value_option %i[until before], inline: true

        execution_option :chdir

        end_of_options as: '--end-of-options'

        # Positional arguments (revisions, file paths, or mixed).
        #
        # In git rev-parse, `--` separates verified arguments from those
        # echoed back without verification. Because this operand is after
        # the end_of_options boundary, callers can freely include `--` and
        # hyphen-prefixed values (e.g. branch names starting with `-`).
        operand :args, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*args, **options)
      #
      #     Execute the `git rev-parse` command
      #
      #     @param args [Array<String>] zero or more revision specifiers,
      #       object names, or file paths to parse. Include `'--'` to
      #       separate verified arguments from those echoed back without
      #       verification, e.g. `call('HEAD', '--', 'file.txt')`.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :revs_only (nil) do not output flags
      #       and parameters not meant for `git rev-list`
      #
      #     @option options [Boolean] :no_revs (nil) do not output flags and
      #       parameters meant for `git rev-list`
      #
      #     @option options [Boolean] :flags (false) do not output non-flag
      #       parameters (`--flags`)
      #
      #     @option options [Boolean] :no_flags (false) do not output flag
      #       parameters (`--no-flags`)
      #
      #     @option options [String] :default (nil) use this value if no
      #       parameter is given by the user
      #
      #     @option options [String] :prefix (nil) behave as if invoked from
      #       this subdirectory of the working tree
      #
      #     @option options [Boolean] :verify (nil) verify that exactly one
      #       parameter is provided and that it can be resolved to an object
      #
      #     @option options [Boolean] :quiet (nil) do not output an error
      #       message if the first argument is not a valid object name;
      #       exit with non-zero status silently
      #
      #       Only meaningful with `:verify`.
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :sq (nil) output a single line
      #       properly quoted for shell consumption
      #
      #     @option options [Boolean, String] :short (nil) shorten the
      #       object name to a unique prefix
      #
      #       When `true`, emits `--short` (git default length). When a
      #       String, emits `--short=<length>`.
      #
      #     @option options [Boolean] :not (nil) prefix object names with
      #       `^` and strip `^` from names that already have one
      #
      #     @option options [Boolean, String] :abbrev_ref (nil) output a
      #       non-ambiguous short name of the object
      #
      #       When `true`, emits `--abbrev-ref`. When a String (`"strict"`
      #       or `"loose"`), emits `--abbrev-ref=<mode>`.
      #
      #     @option options [Boolean] :symbolic (nil) output object names
      #       in a form as close to the original input as possible
      #
      #     @option options [Boolean] :symbolic_full_name (nil) like
      #       `:symbolic` but omit non-ref input and show full refnames
      #
      #     @option options [String] :output_object_format (nil) translate
      #       object identifiers to the specified format
      #
      #       Accepted values are `"sha1"`, `"sha256"`, and `"storage"`.
      #
      #     @option options [Boolean] :all (nil) show all refs found in
      #       `refs/`
      #
      #     @option options [Boolean, String] :branches (nil) show all
      #       branches
      #
      #       When `true`, emits `--branches`. When a String, emits
      #       `--branches=<pattern>`.
      #
      #     @option options [Boolean, String] :tags (nil) show all tags
      #
      #       When `true`, emits `--tags`. When a String, emits
      #       `--tags=<pattern>`.
      #
      #     @option options [Boolean, String] :remotes (nil) show all
      #       remote-tracking branches
      #
      #       When `true`, emits `--remotes`. When a String, emits
      #       `--remotes=<pattern>`.
      #
      #     @option options [String] :glob (nil) show all refs matching
      #       the shell glob pattern
      #
      #     @option options [String, Array<String>] :exclude (nil) exclude
      #       refs matching the glob pattern from the next `--all`,
      #       `--branches`, `--tags`, `--remotes`, or `--glob`
      #
      #     @option options [String] :disambiguate (nil) show every object
      #       whose name begins with the given prefix
      #
      #     @option options [String] :exclude_hidden (nil) do not include
      #       refs that would be hidden by the specified protocol
      #
      #       Accepted values are `"fetch"`, `"receive"`, and `"uploadpack"`.
      #       Affects the next `--all` or `--glob` and is cleared after
      #       processing them.
      #
      #     @option options [Boolean] :local_env_vars (nil) list the
      #       `GIT_*` environment variables local to the repository
      #
      #     @option options [String, Array<String>] :path_format (nil) control
      #       whether paths output by subsequent path-related options are
      #       absolute or relative
      #
      #       Accepted values are `"absolute"` and `"relative"`. May be
      #       given multiple times; each instance affects the arguments
      #       that follow it on the command line.
      #
      #     @option options [Boolean] :git_dir (nil) show `$GIT_DIR` if
      #       defined, otherwise show the path to the `.git` directory
      #
      #     @option options [Boolean] :absolute_git_dir (nil) like
      #       `:git_dir` but always output the canonicalized absolute path
      #
      #     @option options [Boolean] :git_common_dir (nil) show
      #       `$GIT_COMMON_DIR` if defined, else `$GIT_DIR`
      #
      #     @option options [Boolean] :is_inside_git_dir (nil) print
      #       `"true"` when the current working directory is below the
      #       repository directory, `"false"` otherwise
      #
      #     @option options [Boolean] :is_inside_work_tree (nil) print
      #       `"true"` when inside the work tree, `"false"` otherwise
      #
      #     @option options [Boolean] :is_bare_repository (nil) print
      #       `"true"` when the repository is bare, `"false"` otherwise
      #
      #     @option options [Boolean] :is_shallow_repository (nil) print
      #       `"true"` when the repository is shallow, `"false"` otherwise
      #
      #     @option options [String] :resolve_git_dir (nil) check if the
      #       given path is a valid repository or a gitfile that points at
      #       one and print the location
      #
      #     @option options [String] :git_path (nil) resolve
      #       `"$GIT_DIR/<path>"` taking relocation variables into account
      #
      #     @option options [Boolean] :show_cdup (nil) show the path of
      #       the top-level directory relative to the current directory
      #
      #     @option options [Boolean] :show_prefix (nil) show the path of
      #       the current directory relative to the top-level directory
      #
      #     @option options [Boolean] :show_toplevel (nil) show the
      #       absolute path of the top-level directory of the working tree
      #
      #     @option options [Boolean] :show_superproject_working_tree (nil)
      #       show the absolute path of the root of the superproject's
      #       working tree if the current repository is a submodule
      #
      #     @option options [Boolean] :shared_index_path (nil) show the
      #       path to the shared index file in split index mode
      #
      #     @option options [Boolean, String] :show_object_format (nil)
      #       show the object format (hash algorithm) used for the
      #       repository
      #
      #       When `true`, emits `--show-object-format` (defaults to
      #       `"storage"`). When a String (`"storage"`, `"input"`, or
      #       `"output"`), emits `--show-object-format=<mode>`.
      #
      #     @option options [Boolean] :show_ref_format (nil) show the
      #       reference storage format used for the repository
      #
      #     @option options [String] :since (nil) parse the date string
      #       and output the corresponding `--max-age=` parameter
      #
      #       Alias: :after
      #
      #     @option options [String] :until (nil) parse the date string
      #       and output the corresponding `--min-age=` parameter
      #
      #       Alias: :before
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git rev-parse`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero status
    end
  end
end
