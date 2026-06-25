# frozen_string_literal: true

require 'git/config_entry_info'

module Git
  module Parsers
    # Parser for `git config` output
    #
    # Each public method corresponds to a different `git config` sub-command
    # variant and handles the specific output format that variant produces.
    # Most variants are called with `--show-scope --show-origin --null`;
    # `parse_urlmatch` handles the `--get-urlmatch` format where `--show-origin`
    # is unsupported and therefore absent.
    #
    # @api private
    #
    module ConfigEntry
      module_function

      # Parse `git config --get --show-scope --show-origin --null` output
      #
      # Output format (per entry): `scope\0origin\0value\0`
      #
      # The key name is absent from `--get` output and must be supplied by the
      # caller.
      #
      # @param key [String] the config key name that was queried
      #
      # @param output [String] raw stdout from the command
      #
      # @return [Git::ConfigEntryInfo, nil] the parsed entry, or `nil` when not found
      #
      def parse_get(key, output)
        return nil if output.empty?

        scope, origin, value = output.split("\0", -1)
        Git::ConfigEntryInfo.new(scope: scope, origin: origin, key: key, value: value)
      end

      # Parse `git config --get-all --show-scope --show-origin --null` output
      #
      # Output format (per entry): `scope\0origin\0value\0`
      #
      # The key name is absent from `--get-all` output and must be supplied by
      # the caller. Multiple entries appear back-to-back in the same string.
      #
      # @param key [String] the config key name that was queried
      #
      # @param output [String] raw stdout from the command
      #
      # @return [Array<Git::ConfigEntryInfo>] the parsed entries
      #
      def parse_get_all(key, output)
        return [] if output.empty?

        tokens = output.split("\0", -1)
        tokens.pop if tokens.last == ''
        tokens.each_slice(3).map do |scope, origin, value|
          Git::ConfigEntryInfo.new(scope: scope, origin: origin, key: key, value: value)
        end
      end

      # Parse `git config --list --show-scope --show-origin --null` output
      #
      # Also handles `--get-regexp` output, which shares the same format.
      #
      # Output format (per entry): `scope\0origin\0key\nvalue\0`
      #
      # Multiple entries appear back-to-back in the same string.
      #
      # @param output [String] raw stdout from the command
      #
      # @return [Array<Git::ConfigEntryInfo>] the parsed entries
      #
      def parse_list(output)
        return [] if output.empty?

        tokens = output.split("\0", -1)
        tokens.pop if tokens.last == ''
        tokens.each_slice(3).map do |scope, origin, key_value|
          key, value = key_value.split("\n", 2)
          Git::ConfigEntryInfo.new(scope: scope, origin: origin, key: key, value: value || '')
        end
      end

      # Parse `git config --get-urlmatch --show-scope --null` output
      #
      # Handles the two-field-per-entry format produced by `--get-urlmatch` when
      # `--show-scope` is used but `--show-origin` is not (git does not support
      # `--show-origin` with `--get-urlmatch`).
      #
      # Output format (per entry): `scope\0key\nvalue\0`
      #
      # @param output [String] raw stdout from the command
      #
      # @return [Array<Git::ConfigEntryInfo>] the parsed entries; `origin` is `nil` for each
      #
      def parse_urlmatch(output)
        return [] if output.empty?

        tokens = output.split("\0", -1)
        tokens.pop if tokens.last == ''
        tokens.each_slice(2).map do |scope, key_value|
          key, value = key_value.split("\n", 2)
          Git::ConfigEntryInfo.new(scope: scope, origin: nil, key: key, value: value || '')
        end
      end
    end
  end
end
