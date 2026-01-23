# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Branch
      # Implements the `git branch` command for creating new branches
      #
      # This command creates a new branch head pointing to the current HEAD
      # or a specified start point.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Basic branch creation
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch')
      #
      # @example Create branch from a specific start point
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'main')
      #
      # @example Force create (reset existing branch)
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'main', force: true)
      #
      # @example Create with upstream tracking
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'origin/main', track: true)
      #
      # @example Create with inherited tracking configuration
      #   create = Git::Commands::Branch::Create.new(execution_context)
      #   create.call('feature-branch', 'origin/main', track: 'inherit')
      #
      class Create
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          flag :force
          flag :create_reflog
          flag :recurse_submodules
          negatable_flag_or_inline_value :track
          positional :branch_name, required: true
          positional :start_point
        end.freeze

        # Initialize the Create command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch command to create a new branch
        #
        # @overload call(branch_name, start_point = nil, force: nil, create_reflog: nil,
        #   recurse_submodules: nil, track: nil)
        #
        #   @param branch_name [String] The name of the branch to create. Must pass all checks
        #     defined by git-check-ref-format.
        #
        #   @param start_point [String, nil] The commit, branch, or tag to start the new branch from.
        #     If omitted, defaults to HEAD. Can also use `<rev-A>...<rev-B>` syntax for merge base.
        #
        #   @param force [Boolean] Reset the branch to `start_point` even if it already exists.
        #     Without this, git branch refuses to change an existing branch.
        #     Adds `--force` flag.
        #
        #   @param create_reflog [Boolean] Create the branch's reflog, enabling date-based sha1
        #     expressions such as `branch@{yesterday}`. Note that in non-bare repositories,
        #     reflogs are usually enabled by default via `core.logAllRefUpdates`.
        #     Adds `--create-reflog` flag.
        #
        #   @param recurse_submodules [Boolean] Create the branch in the superproject and all
        #     submodules. This is an experimental feature.
        #     Adds `--recurse-submodules` flag.
        #
        #   @param track [Boolean, String, false] Configure upstream tracking for the new branch.
        #     - `true`: Set up tracking using the start-point branch itself (`--track`)
        #     - `false`: Do not set up tracking even if `branch.autoSetupMerge` is set (`--no-track`)
        #     - `'direct'`: Same as `true`, explicitly use start-point as upstream (`--track=direct`)
        #     - `'inherit'`: Copy upstream configuration from start-point branch (`--track=inherit`)
        #
        # @return [String] the command output
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        def call(branch_name, start_point = nil, **)
          args = ARGS.build(branch_name, start_point, **)
          @execution_context.command('branch', *args)
        end
      end
    end
  end
end
