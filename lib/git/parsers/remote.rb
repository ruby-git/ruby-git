# frozen_string_literal: true

require 'git/config_entry_info'
require 'git/remote_info'

module Git
  module Parsers
    # Parser that builds {Git::RemoteInfo} objects from git config entries
    #
    # Accepts `Array<Git::ConfigEntryInfo>` as returned by
    # {Git::Configuring#config_list} and groups entries by remote name,
    # collecting multi-value fields and coercing boolean values.
    #
    # @api private
    #
    module Remote
      module_function

      # Parse an array of config entries into an array of RemoteInfo objects
      #
      # Groups entries whose key matches `remote.<name>.<variable>` by remote
      # name and builds one {Git::RemoteInfo} per unique remote name.
      #
      # Non-remote config entries (keys that do not start with `remote.`) are
      # silently ignored.
      #
      # @param config_entries [Array<Git::ConfigEntryInfo>] all config entries
      #   to inspect; may contain non-remote entries
      #
      # @return [Array<Git::RemoteInfo>] one entry per unique remote name, in
      #   the order the first entry for each name appeared in `config_entries`
      #
      # @raise [ArgumentError] if a boolean config field carries an unrecognized
      #   value (mirrors git's own fatal-error behavior)
      #
      def parse_list(config_entries)
        group_by_remote(config_entries).map { |name, pairs| build_remote_info(name, pairs) }
      end

      # Group config entries by remote name, collecting variable/value pairs
      #
      # @param config_entries [Array<Git::ConfigEntryInfo>]
      #
      # @return [Hash{String => Array}] remote name to variable/value pairs
      #
      # @api private
      #
      def group_by_remote(config_entries)
        config_entries.each_with_object({}) do |entry, groups|
          next unless entry.section == 'remote' && !entry.subsection.empty?

          remote_name = entry.subsection
          variable    = entry.variable.downcase
          groups[remote_name] ||= []
          groups[remote_name] << [variable, entry.value]
        end
      end

      # Config variable names that hold arrays of strings
      ARRAY_VARIABLES = %w[url pushurl fetch push].freeze
      private_constant :ARRAY_VARIABLES

      # Config variable names that hold boolean values
      BOOLEAN_VARIABLES = %w[mirror skipdefaultupdate prune prunetags promisor].freeze
      private_constant :BOOLEAN_VARIABLES

      # Map from git config variable name to RemoteInfo field name (symbol)
      #
      # All keys are lowercase because `git config --list` unconditionally
      # lowercases section names and variable names (subsection names are
      # case-preserved, but are never used as lookup keys here).
      VARIABLE_TO_FIELD = {
        'url' => :url,
        'pushurl' => :push_url,
        'fetch' => :fetch,
        'push' => :push,
        'mirror' => :mirror,
        'skipdefaultupdate' => :skip_default_update,
        'tagopt' => :tag_opt,
        'prune' => :prune,
        'prunetags' => :prune_tags,
        'receivepack' => :receivepack,
        'uploadpack' => :uploadpack,
        'promisor' => :promisor,
        'partialclonefilter' => :partial_clone_filter,
        'vcs' => :vcs
      }.freeze
      private_constant :VARIABLE_TO_FIELD

      # True string values per git's boolean rules
      BOOL_TRUE_VALUES = %w[true yes on 1].freeze
      private_constant :BOOL_TRUE_VALUES

      # False string values per git's boolean rules
      BOOL_FALSE_VALUES = %w[false no off 0].freeze
      private_constant :BOOL_FALSE_VALUES

      # Build a RemoteInfo from grouped variable/value pairs
      #
      # @param remote_name [String]
      #
      # @param pairs [Array] variable/value pairs collected from config entries
      #
      # @return [Git::RemoteInfo]
      #
      # @api private
      #
      def build_remote_info(remote_name, pairs)
        attrs = { name: remote_name }
        pairs.each { |variable, value| apply_pair(attrs, variable, value) }
        Git::RemoteInfo.new(**attrs)
      end

      # Apply a single variable/value pair to an attrs hash
      #
      # @param attrs [Hash] accumulator of RemoteInfo keyword arguments
      #
      # @param variable [String] git config variable name (e.g. 'url', 'tagopt')
      #
      # @param value [String] raw config value
      #
      # @return [void]
      #
      # @api private
      #
      def apply_pair(attrs, variable, value)
        field = VARIABLE_TO_FIELD[variable]
        return unless field # ignore unknown variables

        if ARRAY_VARIABLES.include?(variable)
          attrs[field] ||= []
          attrs[field] << value
        elsif BOOLEAN_VARIABLES.include?(variable)
          attrs[field] = coerce_boolean(variable, value)
        else
          attrs[field] = value
        end
      end

      # Coerce a git config boolean string to a Ruby boolean
      #
      # @param variable [String] the config variable name (for error messages)
      #
      # @param value [String] the raw string value from git config
      #
      # @return [Boolean] `true` or `false`
      #
      # @raise [ArgumentError] if the value is not a recognized boolean
      #
      # @api private
      #
      def coerce_boolean(variable, value)
        normalized = value.downcase
        return true  if BOOL_TRUE_VALUES.include?(normalized) || normalized == ''
        return false if BOOL_FALSE_VALUES.include?(normalized)

        raise ArgumentError,
              "unrecognized boolean value #{value.inspect} for config variable #{variable.inspect}"
      end
    end
  end
end
