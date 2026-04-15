# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Archive creator for files from a named tree via `git archive`
    #
    # Produces an archive of the specified format containing the tree structure
    # for the named tree, and writes it to stdout (or to a file when `out:` or
    # `output:` is given). If `prefix:` is specified it is prepended to the
    # filenames in the archive.
    #
    # @example Archive HEAD as a tar stream to a file
    #   cmd = Git::Commands::Archive.new(execution_context)
    #   File.open('release.tar', 'wb') do |f|
    #     cmd.call('HEAD', format: 'tar', out: f)
    #   end
    #
    # @example Archive a tag with a prefix
    #   cmd = Git::Commands::Archive.new(execution_context)
    #   cmd.call('v1.0', format: 'zip', prefix: 'myproject-1.0/', output: 'release.zip')
    #
    # @example Archive a subdirectory only
    #   cmd = Git::Commands::Archive.new(execution_context)
    #   cmd.call('HEAD', 'src/', format: 'tar', out: io)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-archive/2.53.0
    #
    # @see Git::Commands
    #
    # @see https://git-scm.com/docs/git-archive git-archive
    #
    # @api private
    #
    class Archive < Base
      arguments do
        literal 'archive'
        value_option :format, inline: true                              # --format=<fmt>
        flag_option %i[list l]                                          # --list (alias: :l)
        flag_option %i[verbose v]                                       # --verbose (alias: :v)
        value_option :prefix, inline: true                              # --prefix=<prefix>
        value_option %i[output o], inline: true                         # --output=<file> (alias: :o)
        value_option :add_file, inline: true, repeatable: true          # --add-file=<file>
        value_option :add_virtual_file, inline: true, repeatable: true  # --add-virtual-file=<path>:<content>
        flag_option :worktree_attributes                                # --worktree-attributes
        value_option :mtime, inline: true                               # --mtime=<time>
        value_option :remote, inline: true                              # --remote=<repo>
        value_option :exec, inline: true                                # --exec=<git-upload-archive>
        execution_option :out
        conflicts :output, :out

        end_of_options
        operand :tree_ish
        operand :path, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(tree_ish = nil, *path, **options)
      #
      #     Execute the `git archive` command.
      #
      #     Archive output is binary. On the capturing path (no `out:` option),
      #     `normalize` and `chomp` are disabled so stdout bytes are returned
      #     unchanged. When `out:` is given, the streaming path is used.
      #
      #     @param tree_ish [String, nil] (nil) the tree or commit to produce an archive for;
      #       omit when using the `:list` option to enumerate available formats
      #
      #     @param path [Array<String>] paths within the tree to include in the archive
      #
      #     @param options [Hash] command options
      #
      #     @option options [String] :format (nil) archive format — `tar`, `zip`, `tar.gz`,
      #       `tgz`, or any format defined via `tar.<format>.command`
      #
      #     @option options [Boolean] :list (false) show all available archive formats
      #
      #       Alias: :l
      #
      #     @option options [Boolean] :verbose (false) report progress to stderr
      #
      #       Alias: :v
      #
      #     @option options [String] :prefix (nil) prepend `<prefix>/` to each filename
      #       in the archive
      #
      #     @option options [String] :output (nil) write the archive to this file instead
      #       of stdout
      #
      #       Alias: :o
      #
      #     @option options [String, Array<String>] :add_file (nil) add one or more
      #       non-tracked files to the archive; may be passed multiple times
      #
      #     @option options [String, Array<String>] :add_virtual_file (nil) add one or
      #       more virtual files by `<path>:<content>`; may be passed multiple times
      #
      #     @option options [Boolean] :worktree_attributes (false) look for attributes in
      #       `.gitattributes` files in the working tree as well
      #
      #     @option options [String] :mtime (nil) set modification time of archive entries
      #
      #     @option options [String] :remote (nil) retrieve a tar archive from a remote
      #       repository instead of the local one
      #
      #     @option options [String] :exec (nil) path to `git-upload-archive` on the remote
      #       side; used with `:remote`
      #
      #     @option options [IO, #write] :out (nil) stream archive output to this IO object
      #       instead of capturing it; the result's `.stdout` will be `''`
      #
      #     @return [Git::CommandLineResult] the result of calling `git archive`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #     @api public

      # Archive output is intrinsically binary (tar, zip, etc.) — opt out of
      # Ruby string normalization and trailing-newline chomping so that
      # `result.stdout` bytes are returned unchanged. Only affects the
      # capturing path; streaming via `out:` is never normalized or chomped
      # regardless of these settings.
      #
      # @return [Boolean] `false`
      #
      def normalize_captured_stdout? = false

      # Archive output is binary, so preserve captured stdout byte-for-byte
      # even when it ends with a newline.
      #
      # @return [Boolean] `false`
      #
      def chomp_captured_stdout? = false
    end
  end
end
