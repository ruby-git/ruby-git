# frozen_string_literal: true

module Git
  module Parsers
    # Parser for `git ls-remote` command output
    #
    # @api private
    #
    module LsRemote
      module_function

      # Parse `git ls-remote` stdout lines into a structured Hash
      #
      # @param lines [Array<String>] the individual stdout lines
      #
      # @return [Hash{String => Hash}] a map of ref type to ref data
      #
      #   The structure differs by key:
      #
      #   - `"head"` maps directly to `{ ref: String, sha: String }`
      #   - Other keys (e.g. `"branches"`, `"tags"`) map to
      #     `{ name => { ref: String, sha: String } }`
      #
      def parse_output(lines)
        lines.each_with_object(Hash.new { |h, k| h[k] = {} }) do |line, hsh|
          type, name, value = parse_line(line)
          if name
            hsh[type][name] = value
          else
            hsh[type].update(value)
          end
        end
      end

      # Parse a single `git ls-remote` output line
      #
      # @param line [String] a single line from ls-remote stdout
      #
      # @return [Array(String, String|nil, Hash)] `[type, name, value]` where
      #   `value` is `{ ref: String, sha: String }`
      #
      # @raise [Git::UnexpectedResultError] if the line is not in `<sha>\t<ref>` format
      #
      def parse_line(line)
        unless line.include?("\t") && line.match?(/\A[0-9a-f]{4,}\t/)
          raise Git::UnexpectedResultError, "Unexpected ls-remote output line: #{line.inspect}"
        end

        sha, info = line.split("\t", 2)
        ref, type, name = info.split('/', 3)

        type ||= 'head'
        type = 'branches' if type == 'heads'

        value = { ref: ref, sha: sha }

        [type, name, value]
      end

      # Parse `git ls-remote --symref <repo> HEAD` output into a branch name
      #
      # @param output [String] command stdout
      #
      # @return [String] the default branch name
      #
      # @raise [Git::UnexpectedResultError] when the branch cannot be determined
      #
      def parse_default_branch(output)
        match_data = output.match(%r{^ref: refs/remotes/[^/]+/(?<default_branch>[^\t]+)\t})
        return match_data[:default_branch] if match_data

        match_data = output.match(%r{^ref: refs/heads/(?<default_branch>[^\t]+)\tHEAD$})
        return match_data[:default_branch] if match_data

        raise Git::UnexpectedResultError, 'Unable to determine the default branch'
      end
    end
  end
end
