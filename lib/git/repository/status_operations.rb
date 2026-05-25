# frozen_string_literal: true

require 'git/commands/ls_files'
require 'git/commands/rev_parse'
require 'git/escaped_path'
require 'git/status'

module Git
  class Repository
    # Facade methods for repository-status operations
    #
    # Provides methods for querying the state of the repository: checking
    # whether any commits exist, listing untracked working-tree files, and
    # listing files tracked in the index.
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module StatusOperations
      # Returns `true` if the repository has no commits yet
      #
      # Checks whether `HEAD` can be resolved to a commit object. A brand-new
      # repository (or one created with `git checkout --orphan`) where no commit
      # has been made yet will have no commits.
      #
      # @example Check whether a repository is empty
      #   repo.no_commits? #=> true   # freshly initialized, no commits yet
      #   repo.no_commits? #=> false  # at least one commit exists
      #
      # @return [Boolean] `true` when the repository has no commits, `false` otherwise
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status other
      #   than when the repository has no commits
      #
      def no_commits?
        Git::Commands::RevParse.new(@execution_context).call('HEAD', verify: true)
        false
      rescue Git::FailedError => e
        raise unless e.result.status.exitstatus == 128 &&
                     e.result.stderr == 'fatal: Needed a single revision'

        true
      end

      # List all files in the working tree that are not tracked by git
      #
      # Runs `git ls-files --others --exclude-standard` from the working tree
      # root and returns an array of repository-relative file paths. Files that
      # match `.gitignore` or other standard exclusion rules are omitted.
      #
      # @example Get untracked files
      #   repo.untracked_files #=> ["new_feature.rb", "tmp/debug.log"]
      #
      # @example No untracked files
      #   repo.untracked_files #=> []
      #
      # @return [Array<String>] repository-relative paths of untracked,
      #   non-ignored files; empty when there are none
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def untracked_files
        Git::Commands::LsFiles.new(@execution_context).call(
          others: true, exclude_standard: true, chdir: @execution_context.git_work_dir
        ).stdout.split("\n").map { |f| Private.unescape_quoted_path(f) }
      end

      # Returns a {Git::Status} object describing the working tree and index state
      #
      # Constructs a {Git::Status} for this repository by collecting information from
      # `git ls-files --stage`, `git ls-files --others`, `git diff-files`, and
      # `git diff-index HEAD` (the last only when at least one commit exists). The
      # result identifies which files have been modified, added, deleted, or are
      # untracked.
      #
      # @example Check which files are modified
      #   repo.status.changed #=> { "lib/foo.rb" => <Git::Status::StatusFile ...> }
      #
      # @example Check for untracked files
      #   repo.status.untracked #=> { "new_file.rb" => <Git::Status::StatusFile ...> }
      #
      # @example Iterate over all status files
      #   repo.status.each { |file| puts "#{file.path}: #{file.type}" }
      #
      # @return [Git::Status] the status of the repository
      #
      # @raise [Git::FailedError] if any underlying git command exits with a
      #   non-zero exit status
      #
      def status
        Git::Status.new(self)
      end

      # List all files tracked in the index
      #
      # Runs `git ls-files --stage` under the given `location` and returns a
      # hash keyed by file path with per-file index metadata.
      #
      # @example List all indexed files in the working tree
      #   repo.ls_files
      #   #=> { "README.md" => { path: "README.md", mode_index: "100644",
      #   #=>                    sha_index: "abc123...", stage: "0" }, ... }
      #
      # @example List indexed files under a specific directory
      #   repo.ls_files('lib/')
      #   #=> { "lib/git.rb" => { path: "lib/git.rb", ... }, ... }
      #
      # @param location [String, nil] the path to restrict the listing to;
      #   defaults to `'.'` (all tracked files) when `nil`
      #
      # @return [Hash{String => Hash}] a hash of index entries keyed by file path
      #
      #   Each value is a Hash with the following keys:
      #   * `:path` [String] the file path
      #   * `:mode_index` [String] the file's index mode (e.g. `"100644"`)
      #   * `:sha_index` [String] the file's index SHA
      #   * `:stage` [String] the merge stage (`"0"` for normal entries)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def ls_files(location = nil)
        location ||= '.'
        {}.tap do |files|
          Git::Commands::LsFiles.new(@execution_context).call(location, stage: true).stdout.split("\n").each do |line|
            info, file = Private.split_status_line(line)
            mode, sha, stage = info.split
            files[file] = { path: file, mode_index: mode, sha_index: sha, stage: stage }
          end
        end
      end

      # Private helpers local to {Git::Repository::StatusOperations}
      #
      # @api private
      #
      module Private
        module_function

        # Split a tab-delimited status line from `git ls-files --stage` output
        #
        # The output format is `<mode> <sha> <stage>\t<file>`. Quoted file paths
        # (which git uses when the path contains non-ASCII or special characters)
        # are unescaped before being returned. `line` is assumed to be non-empty
        # because `git ls-files --stage` never emits blank lines.
        #
        # @param line [String] a single line of git ls-files output
        #
        # @return [Array<String>] the tab-delimited parts with the last part
        #   unescaped when it was git-quoted
        #
        def split_status_line(line)
          parts = line.split("\t")
          parts[-1] = unescape_quoted_path(parts[-1])
          parts
        end

        # Unescape a git-quoted path
        #
        # Git wraps paths containing non-ASCII or special characters in
        # double-quotes and octal-escapes each byte. This method strips the
        # surrounding quotes and delegates unescaping to {Git::EscapedPath}.
        #
        # @param path [String] the path as it appears in git output
        #
        # @return [String] the unescaped path
        #
        def unescape_quoted_path(path)
          if path.start_with?('"') && path.end_with?('"')
            Git::EscapedPath.new(path[1..-2]).unescape
          else
            path
          end
        end
      end

      private_constant :Private
    end
  end
end
