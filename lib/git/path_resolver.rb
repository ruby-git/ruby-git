# frozen_string_literal: true

require 'git/commands/rev_parse'
require 'git/errors'
require 'git/execution_context'
require 'git/execution_context/global'
require 'git/system_call_guard'

module Git
  # Resolves and normalizes the filesystem paths that locate a Git repository
  #
  # `PathResolver` is the single home for the path-resolution logic used by the
  # `Git` factory methods ({Git.open}, {Git.bare}, {Git.init}, and {Git.clone}).
  # It computes the absolute working-directory, repository (`.git`), and index
  # paths from the caller-supplied values, following the same rules Git itself
  # uses (including gitdir-pointer files for submodules and linked worktrees).
  #
  # A relative path given by the caller is expanded against the process working
  # directory, as git does for a path on its command line. Only the defaults are
  # derived from the layout: an omitted repository is `<working_directory>/.git`
  # and an omitted index is `<repository>/index`.
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
    #   Git::PathResolver.resolve_paths(working_directory: '/repo')
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
    # @raise [Git::Error] if the repository path is a gitdir pointer file that
    #   cannot be read
    #
    def resolve_paths(working_directory: nil, repository: nil, index: nil, bare: false)
      working_dir = resolve_working_directory(working_directory, bare: bare)
      repo_path = resolve_repository(repository, working_dir)
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
    #   Git::PathResolver.root_of_worktree('/repo/subdir') #=> '/repo'
    #
    # @param working_dir [String] a path inside the working tree
    #
    # @param binary_path [String, :use_global_config] path to the git binary
    #
    #   Controls which git binary is invoked during root detection. Defaults to
    #   `:use_global_config`, which resolves to `Git.config.binary_path`.
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
    # @raise [Git::Error] if the git binary cannot be found or fails to launch, or
    #   if `working_dir` cannot be expanded to an absolute path
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
    # @raise [ArgumentError] if `working_dir` is not inside a git working tree
    #
    # @raise [Git::Error] if the git binary cannot be found or fails to launch, or
    #   if `working_dir` cannot be expanded to an absolute path
    #
    # @api private
    #
    def execute_rev_parse_toplevel(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
      execution_context = Git::ExecutionContext::Global.new(binary_path: binary_path, git_ssh: git_ssh)
      expanded_dir = expand_path(working_dir, 'Failed to expand the working directory path')

      Git::Commands::RevParse.new(execution_context).call(show_toplevel: true, chdir: expanded_dir).stdout
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
    # @raise [Git::Error] if the path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def resolve_working_directory(path, bare:)
      return nil if bare

      expand_path(path, 'Failed to resolve the working directory')
    end
    private_class_method :resolve_working_directory

    # Resolve the repository (`.git`) directory path
    #
    # Handles the gitdir-pointer file case for submodules and linked worktrees.
    #
    # @param path [String, nil] the repository path or `nil`
    #
    # @param working_dir [String, nil] the working directory whose `.git` is the
    #   default when `path` is `nil`, or `nil` for a bare repository, whose
    #   default is the process working directory
    #
    # @return [String] the absolute path to the repository
    #
    # @raise [Git::Error] if the path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def resolve_repository(path, working_dir)
      initial_path =
        if working_dir && path.nil?
          File.join(working_dir, '.git')
        else
          expand_path(path, 'Failed to resolve the repository directory')
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
    # @raise [Git::Error] if `path` is a file that cannot be read
    #
    # Relative pointer targets are resolved from the directory containing the
    # pointer file itself, matching git's pointer-file semantics.
    #
    # @api private
    #
    def resolve_gitdir_pointer(path)
      return path unless File.file?(path)

      gitdir_content = Git::SystemCallGuard.call('Failed to read the gitdir pointer file') { File.read(path) }.strip
      return path unless gitdir_content.start_with?('gitdir: ')

      gitdir_path = gitdir_content.sub(/\Agitdir: /, '')
      File.expand_path(gitdir_path, File.dirname(path))
    end
    private_class_method :resolve_gitdir_pointer

    # Resolve the index file path
    #
    # @param path [String, nil] the index path or `nil`
    #
    # @param repository [String] the repository directory whose `index` is the
    #   default when `path` is `nil`
    #
    # @return [String] the absolute path to the index file
    #
    # @raise [Git::Error] if the path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def resolve_index(path, repository)
      return File.join(repository, 'index') unless path

      expand_path(path, 'Failed to resolve the index file')
    end
    private_class_method :resolve_index

    # Expand a path against the process working directory
    #
    # @param path [String, nil] the path to expand, or `nil` for the process
    #   working directory itself
    #
    # @param message [String] the message of the {Git::Error} raised when the
    #   expansion fails
    #
    # @return [String] the absolute path
    #
    # @raise [Git::Error] if the path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def expand_path(path, message)
      Git::SystemCallGuard.call(message) { File.expand_path(path || Dir.pwd) }
    end
    private_class_method :expand_path
  end
end
