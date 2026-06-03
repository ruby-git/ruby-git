# frozen_string_literal: true

require 'git/commands/rev_parse'
require 'git/errors'
require 'git/execution_context'

module Git
  class Repository
    # Resolves and normalizes the filesystem paths that locate a Git repository
    #
    # `PathResolver` is the single home for the path-resolution logic used by the
    # `Git::Repository` factory class methods ({Git::Repository.open} and
    # {Git::Repository.bare}). It computes the absolute working-directory,
    # repository (`.git`), and index paths from the caller-supplied values,
    # following the same rules Git itself uses (including gitdir-pointer files for
    # submodules and linked worktrees).
    #
    # @api private
    #
    module PathResolver
      module_function

      # Resolve and normalize the paths that locate a Git repository
      #
      # Returns a new hash containing the resolved absolute paths for:
      #   * `:working_directory` — the working tree root (`nil` for bare repos)
      #   * `:repository` — the `.git` directory
      #   * `:index` — the index file
      #
      # This method does not mutate any inputs.
      #
      # @example Resolve paths for a working tree
      #   Git::Repository::PathResolver.resolve_paths(working_directory: '/repo')
      #   #=> { working_directory: '/repo', repository: '/repo/.git', index: '/repo/.git/index' }
      #
      # @param working_directory [String, nil] the working directory path
      #
      # @param repository [String, nil] the repository (`.git`) directory path
      #
      # @param index [String, nil] the index file path
      #
      # @param bare [Boolean] whether this is a bare repository
      #
      # @return [Hash{Symbol => (String, nil)}] a hash with `:working_directory`,
      #   `:repository`, and `:index` keys
      #
      def resolve_paths(working_directory: nil, repository: nil, index: nil, bare: false)
        working_dir = resolve_working_directory(working_directory, bare: bare)
        # For bare repos, use working_directory as the default repository location
        repo_path = resolve_repository(repository, working_dir, bare: bare, bare_default: working_directory)
        index_path = resolve_index(index, repo_path)

        {
          working_directory: working_dir,
          repository: repo_path,
          index: index_path
        }
      end

      # Find the root of the working tree that contains `working_dir`
      #
      # Runs `git rev-parse --show-toplevel` from `working_dir` to locate the
      # top-level directory of the working tree.
      #
      # @example Find the worktree root from a subdirectory
      #   Git::Repository::PathResolver.root_of_worktree('/repo/subdir') #=> '/repo'
      #
      # @param working_dir [String] a path inside the working tree
      #
      # @param binary_path [String, :use_global_config] path to the git binary
      #
      #   Controls which git binary is invoked during root detection. Defaults to
      #   `:use_global_config`, which resolves to `Git::Base.config.binary_path`.
      #
      # @param git_ssh [String, nil, :use_global_config] the SSH wrapper path
      #
      #   Forwarded as `GIT_SSH`. Defaults to `:use_global_config`.
      #
      # @return [String] the absolute path to the root of the working tree
      #
      # @raise [ArgumentError] if `working_dir` does not exist, is not a
      #   directory, or is not inside a git working tree
      #
      #   Also raised if the git binary cannot be found.
      #
      def root_of_worktree(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
        raise ArgumentError, "'#{working_dir}' does not exist or is not a directory" unless Dir.exist?(working_dir)

        execute_rev_parse_toplevel(working_dir, binary_path: binary_path, git_ssh: git_ssh)
      end

      # Run `git rev-parse --show-toplevel` from `working_dir` and return stdout
      #
      # @param working_dir [String] a path inside the working tree
      #
      # @param binary_path [String, :use_global_config] path to the git binary
      #
      # @param git_ssh [String, nil, :use_global_config] the SSH wrapper path
      #
      # @return [String] the top-level directory reported by git
      #
      # @raise [ArgumentError] if the git binary is not found or `working_dir` is
      #   not inside a git working tree
      #
      # @api private
      #
      def execute_rev_parse_toplevel(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
        execution_context = Git::ExecutionContext::Global.new(binary_path: binary_path, git_ssh: git_ssh)
        Git::Commands::RevParse.new(execution_context).call(
          show_toplevel: true, chdir: File.expand_path(working_dir)
        ).stdout
      rescue Errno::ENOENT
        raise ArgumentError, 'Failed to find the root of the worktree: git binary not found'
      rescue Git::FailedError
        raise ArgumentError, "'#{working_dir}' is not in a git working tree"
      end
      private_class_method :execute_rev_parse_toplevel

      # Resolve the working directory path
      #
      # @param path [String, nil] the working directory path or `nil`
      #
      # @param bare [Boolean] whether this is a bare repository
      #
      # @return [String, nil] the absolute path, or `nil` for bare repos
      #
      # @api private
      #
      def resolve_working_directory(path, bare:)
        return nil if bare

        File.expand_path(path || Dir.pwd)
      end
      private_class_method :resolve_working_directory

      # Resolve the repository (`.git`) directory path
      #
      # Handles the gitdir-pointer file case for submodules and linked worktrees.
      #
      # @param path [String, nil] the repository path or `nil`
      #
      # @param working_dir [String, nil] the working directory used for relative
      #   path resolution
      #
      # @param bare [Boolean] whether this is a bare repository
      #
      # @param bare_default [String, nil] for bare repos, used as the default when
      #   `path` is `nil`
      #
      # @return [String] the absolute path to the repository
      #
      # @api private
      #
      def resolve_repository(path, working_dir, bare:, bare_default: nil)
        initial_path = if bare
                         File.expand_path(path || bare_default || Dir.pwd)
                       else
                         File.expand_path(path || '.git', working_dir)
                       end

        resolve_gitdir_pointer(initial_path)
      end
      private_class_method :resolve_repository

      # Resolve gitdir-pointer files used by submodules and linked worktrees
      #
      # If `path` points to a file containing `"gitdir: <path>"`, returns the
      # resolved target path. Otherwise returns `path` unchanged.
      #
      # @param path [String] the path to check
      #
      # @return [String] the resolved absolute path
      #
      # Relative pointer targets are resolved from the directory containing the
      # pointer file itself, matching git's pointer-file semantics.
      #
      # @api private
      #
      def resolve_gitdir_pointer(path)
        return path unless File.file?(path)

        gitdir_content = File.read(path).strip
        return path unless gitdir_content.start_with?('gitdir: ')

        gitdir_path = gitdir_content.sub(/\Agitdir: /, '')
        File.expand_path(gitdir_path, File.dirname(path))
      end
      private_class_method :resolve_gitdir_pointer

      # Resolve the index file path
      #
      # @param path [String, nil] the index path or `nil`
      #
      # @param repository [String] the repository directory used for relative
      #   path resolution
      #
      # @return [String] the absolute path to the index file
      #
      # @api private
      #
      def resolve_index(path, repository)
        File.expand_path(path || 'index', repository)
      end
      private_class_method :resolve_index
    end
  end
end
