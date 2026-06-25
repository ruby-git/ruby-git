# frozen_string_literal: true

module Git
  # Represents a single Git configuration entry
  #
  # Returned by {Git::Configuring} read operations such as {Git::Configuring#config_get},
  # {Git::Configuring#config_get_all}, {Git::Configuring#config_list}, and their
  # related methods.
  #
  # @example Create a ConfigEntryInfo
  #   entry = Git::ConfigEntryInfo.new(
  #     scope: 'local',
  #     origin: 'file:.git/config',
  #     key: 'remote.origin.url',
  #     value: 'https://github.com/ruby-git/ruby-git'
  #   )
  #   entry.section    # => "remote"
  #   entry.subsection # => "origin"
  #   entry.variable   # => "url"
  #
  # @api public
  #
  # @!attribute [r] scope
  #
  #   The scope of the configuration entry
  #
  #   May be one of `"system"`, `"global"`, `"local"`, `"worktree"`, `"command"`,
  #   `"file"`, or `"blob"`. The `"command"` scope is used for values supplied
  #   via the command line (including default values from `--default`).
  #
  #   @return [String] the config scope string (e.g. `"local"`, `"global"`)
  #
  # @!attribute [r] origin
  #
  #   Where the configuration entry originates
  #
  #   The origin is in the format `<origin-type>:<actual-origin>` and is never
  #   blank. The origin type prefix is one of `file:`, `blob:`, `command line:`,
  #   or `standard input:`.
  #
  #   `nil` when the git command used to retrieve this entry does not support
  #   `--show-origin` (currently only `--get-urlmatch`).
  #
  #   @return [String, nil] the origin path in the format `<type>:<path>`, or `nil`
  #
  # @!attribute [r] key
  #
  #   The full dotted key name of the configuration entry (e.g., `remote.origin.url`)
  #
  #   @return [String] the full dotted key name (e.g. `remote.origin.url`)
  #
  # @!attribute [r] value
  #
  #   The value of the configuration entry
  #
  #   @return [String] the string value of this entry
  #
  ConfigEntryInfo = Data.define(:scope, :origin, :key, :value) do
    # Returns the section component of the key (everything before the first dot)
    #
    # Returns an empty string when the key contains no dot.
    #
    # @example Section component of a dotted key
    #   entry.section # => "remote"
    #
    # @return [String] the section name, or an empty string when the key has no dot
    #
    def section = first_dot ? key[0...first_dot] : ''

    # Returns the subsection component of the key (everything between the first and last dot)
    #
    # Returns an empty string when the key has zero or one dot (no subsection).
    #
    # @example Subsection component of a dotted key
    #   entry.subsection # => "origin"
    #
    # @return [String] the subsection name, or an empty string when there is no subsection
    #
    def subsection = first_dot && first_dot != last_dot ? key[(first_dot + 1)...last_dot] : ''

    # Returns the variable component of the key (everything after the last dot)
    #
    # Returns the full key when the key contains no dot.
    #
    # @example Variable component of a dotted key
    #   entry.variable # => "url"
    #
    # @return [String] the variable name (everything after the last dot)
    #
    def variable = last_dot ? key[(last_dot + 1)..] : key

    private

    # Returns the index of the first dot in the key, or nil if none exists
    #
    # @return [Integer, nil] the zero-based index of the first dot, or `nil`
    #
    def first_dot = key.index('.')

    # Returns the index of the last dot in the key, or nil if none exists
    #
    # @return [Integer, nil] the zero-based index of the last dot, or `nil`
    #
    def last_dot = key.rindex('.')
  end
end
