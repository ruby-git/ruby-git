# frozen_string_literal: true

require 'git/escaped_path'

module Git
  module Parsers
    # Parser for `git ls-tree` output
    #
    # Provides a class method that transforms raw `git ls-tree` output into a
    # structured Hash consumed by the `Git::Repository::ObjectOperations` facade.
    #
    # @api private
    #
    module LsTree
      module_function

      # Parse `git ls-tree` output into a type-keyed hash of entries
      #
      # Each line of output is expected in the format produced by
      # `git ls-tree`: `<mode> <type> <sha>\t<file>`.
      #
      # @param output [String] raw stdout from `git ls-tree`
      #
      # @return [Hash<String, Hash<String, Hash>>] hash keyed by object type
      #   (`'blob'`, `'tree'`, `'commit'`), then by filename, holding
      #   `:mode` and `:sha` values
      #
      # @api private
      #
      def parse(output)
        data = { 'blob' => {}, 'tree' => {}, 'commit' => {} }
        output.split("\n").each do |line|
          info, filenm = line.split("\t", 2)
          filenm = unescape_path(filenm) if filenm
          mode, type, entry_sha = info.split
          data[type][filenm] = { mode: mode, sha: entry_sha }
        end
        data
      end

      # Converts a git-quoted path back to its original form
      #
      # @param path [String] the path, possibly git-quoted
      #
      # @return [String] the unquoted path
      #
      # @api private
      #
      def unescape_path(path)
        if path.start_with?('"') && path.end_with?('"')
          Git::EscapedPath.new(path[1..-2]).unescape
        else
          path
        end
      end
    end
  end
end
