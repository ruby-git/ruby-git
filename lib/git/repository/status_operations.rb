# frozen_string_literal: true

require 'git/commands/ls_files'
require 'git/escaped_path'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for repository-status operations
    #
    # Provides methods for querying the state of the index and working tree,
    # including listing files tracked in the index.
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module StatusOperations
      # List all files tracked in the index
      #
      # Runs `git ls-files --stage` under the given `location` and returns a
      # hash keyed by file path with per-file index metadata.
      #
      # @overload ls_files(location = nil)
      #
      #   @example List all indexed files in the working tree
      #     repo.ls_files
      #     #=> { "README.md" => { path: "README.md", mode_index: "100644",
      #     #=>                    sha_index: "abc123...", stage: "0" }, ... }
      #
      #   @example List indexed files under a specific directory
      #     repo.ls_files('lib/')
      #     #=> { "lib/git.rb" => { path: "lib/git.rb", ... }, ... }
      #
      #   @param location [String, nil] the directory or file path to restrict the
      #     listing to; defaults to `'.'` (all files in the working tree)
      #
      #   @return [Hash{String => Hash}] a hash of files in the index where each
      #     key is the file path and each value is a Hash containing:
      #     * `:path` [String] the file path
      #     * `:mode_index` [String] the file's index mode (e.g. `"100644"`)
      #     * `:sha_index` [String] the file's index SHA
      #     * `:stage` [String] the merge stage (`"0"` for normal entries)
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
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
        # are unescaped before being returned.
        #
        # @param line [String] a single line of git ls-files output
        #
        # @return [Array<String>] the tab-delimited parts with the last part
        #   unescaped when it was git-quoted
        #
        def split_status_line(line)
          parts = line.split("\t")
          parts[-1] = unescape_quoted_path(parts[-1]) if parts.any?
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
