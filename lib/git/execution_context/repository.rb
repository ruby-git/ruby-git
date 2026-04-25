# frozen_string_literal: true

require 'git/execution_context'

module Git
  class ExecutionContext
    # Execution context for repository-bound git commands
    #
    # Manages the git environment for commands that operate within an existing
    # repository — setting `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, and
    # `GIT_SSH` — and prepending `--git-dir` / `--work-tree` to every git
    # invocation via {#global_opts}.
    #
    # ### Construction
    #
    # Prefer the factory class methods over `new` when building from a
    # {Git::Base} object or a hash:
    #
    #   context = Git::ExecutionContext::Repository.from_base(base)
    #   context = Git::ExecutionContext::Repository.from_hash(repository: '/repo/.git', ...)
    #
    # @api private
    #
    class Repository < ExecutionContext
      # Creates a Repository context from a {Git::Base} instance
      #
      # @param base_object [Git::Base] the base Git object to derive context from
      #
      # @param logger [Logger, nil] logger forwarded to the CommandLine layer;
      #   `nil` uses a null logger (see {Git::ExecutionContext#initialize})
      #
      # @return [Git::ExecutionContext::Repository] the new repository context
      #
      def self.from_base(base_object, logger: nil)
        new(
          git_dir: base_object.repo.to_s,
          git_index_file: base_object.index&.to_s,
          git_work_dir: base_object.dir&.to_s,
          git_ssh: base_object.git_ssh,
          logger: logger
        )
      end

      # Creates a Repository context from the hash format used by {Git::Base.new}
      #
      # Expected keys: `:repository`, `:working_directory`, `:index`, `:git_ssh`
      #
      # @param base_hash [Hash] the hash of repository configuration values
      #
      # @param logger [Logger, nil] logger forwarded to the CommandLine layer;
      #   `nil` uses a null logger (see {Git::ExecutionContext#initialize})
      #
      # @return [Git::ExecutionContext::Repository] the new repository context
      #
      def self.from_hash(base_hash, logger: nil)
        new(
          git_dir: base_hash[:repository],
          git_index_file: base_hash[:index],
          git_work_dir: base_hash[:working_directory],
          git_ssh: base_hash.key?(:git_ssh) ? base_hash[:git_ssh] : :use_global_config,
          logger: logger
        )
      end

      # Creates a new repository execution context
      #
      # @param git_dir [String, nil] path to the `.git` directory
      #
      # @param git_work_dir [String, nil] path to the working tree
      #
      # @param git_index_file [String, nil] path to the index file
      #
      # @param git_ssh [String, nil, :use_global_config] SSH wrapper path, `nil` to
      #   unset, or `:use_global_config` (default) to inherit from {Git::Base.config}
      #
      # @param logger [Logger, nil] logger forwarded to the CommandLine layer;
      #   `nil` uses a null logger (see {Git::ExecutionContext#initialize})
      #
      def initialize(git_dir:, git_work_dir: nil, git_index_file: nil, git_ssh: :use_global_config, logger: nil)
        super(git_ssh: git_ssh, logger: logger)
        @git_dir = git_dir
        @git_work_dir = git_work_dir
        @git_index_file = git_index_file
      end

      # @return [String, nil] path to the `.git` directory
      attr_reader :git_dir

      # @return [String, nil] path to the working tree
      attr_reader :git_work_dir

      # @return [String, nil] path to the index file
      attr_reader :git_index_file
    end
  end
end
