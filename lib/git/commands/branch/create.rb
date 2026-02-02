# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/branch/list'

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
        ARGS = Arguments.define do
          static 'branch'
          flag :force
          flag :create_reflog
          flag :recurse_submodules
          flag_or_value :track, negatable: true, inline: true
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
        # @overload call(branch_name, **options)
        #
        #   Create a new branch from the current HEAD
        #
        #   @param branch_name [String] The name of the branch to create
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Reset the branch to `start_point` even if it already exists.
        #     Without this, git branch refuses to change an existing branch.
        #     Adds `--force` flag.
        #
        #   @option options [Boolean] :create_reflog (nil) Create the branch's reflog, enabling date-based sha1
        #     expressions such as `branch@{yesterday}`. Note that in non-bare repositories,
        #     reflogs are usually enabled by default via `core.logAllRefUpdates`.
        #     Adds `--create-reflog` flag.
        #
        #   @option options [Boolean] :recurse_submodules (nil) Create the branch in the superproject and all
        #     submodules. This is an experimental feature.
        #     Adds `--recurse-submodules` flag.
        #
        #   @option options [Boolean, String, false] :track (nil) Configure upstream tracking for the new branch.
        #     - `true`: Set up tracking using the start-point branch itself (`--track`)
        #     - `false`: Do not set up tracking even if `branch.autoSetupMerge` is set (`--no-track`)
        #     - `'direct'`: Same as `true`, explicitly use start-point as upstream (`--track=direct`)
        #     - `'inherit'`: Copy upstream configuration from start-point branch (`--track=inherit`)
        #
        # @overload call(branch_name, start_point, **options)
        #
        #   Create a new branch from the specified start point
        #
        #   @param branch_name [String] The name of the branch to create
        #
        #   @param start_point [String, nil] The commit, branch, or tag to start the new branch from.
        #     Can also use `<rev-A>...<rev-B>` syntax for merge base.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Reset the branch to `start_point` even if it already exists.
        #     Without this, git branch refuses to change an existing branch.
        #     Adds `--force` flag.
        #
        #   @option options [Boolean] :create_reflog (nil) Create the branch's reflog, enabling date-based sha1
        #     expressions such as `branch@{yesterday}`. Note that in non-bare repositories,
        #     reflogs are usually enabled by default via `core.logAllRefUpdates`.
        #     Adds `--create-reflog` flag.
        #
        #   @option options [Boolean] :recurse_submodules (nil) Create the branch in the superproject and all
        #     submodules. This is an experimental feature.
        #     Adds `--recurse-submodules` flag.
        #
        #   @option options [Boolean, String, false] :track (nil) Configure upstream tracking for the new branch.
        #     - `true`: Set up tracking using the start-point branch itself (`--track`)
        #     - `false`: Do not set up tracking even if `branch.autoSetupMerge` is set (`--no-track`)
        #     - `'direct'`: Same as `true`, explicitly use start-point as upstream (`--track=direct`)
        #     - `'inherit'`: Copy upstream configuration from start-point branch (`--track=inherit`)
        #
        # @return [Git::BranchInfo] the info for the branch that was created
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        def call(branch_name, *, **)
          command_args = ARGS.build(branch_name, *, **)
          @execution_context.command(*command_args)

          # Get branch info for the newly created branch
          Git::Commands::Branch::List.new(@execution_context).call(branch_name).first
        end
      end
    end
  end
end
