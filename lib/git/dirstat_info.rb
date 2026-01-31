# frozen_string_literal: true

module Git
  # Immutable value object representing a single directory's contribution to a diff
  #
  # @api public
  #
  # @example
  #   info = Git::DirstatEntry.new(directory: 'lib/commands/', percentage: 45.2)
  #   info.directory   #=> "lib/commands/"
  #   info.percentage  #=> 45.2
  #
  # @!attribute [r] directory
  #   @return [String] the directory path (always ends with '/')
  #
  # @!attribute [r] percentage
  #   @return [Float] the percentage of changes in this directory (0.0-100.0)
  #
  DirstatEntry = Data.define(:directory, :percentage)

  # Immutable result object from git --dirstat output
  #
  # Contains the list of directories and their contribution percentages to the diff.
  #
  # @api public
  #
  # @example
  #   dirstat = Git::DirstatInfo.new(
  #     entries: [
  #       Git::DirstatEntry.new(directory: 'lib/commands/', percentage: 45.2),
  #       Git::DirstatEntry.new(directory: 'spec/unit/', percentage: 30.1)
  #     ]
  #   )
  #   dirstat.entries.first.directory  #=> "lib/commands/"
  #   dirstat['lib/commands/']         #=> 45.2
  #   dirstat.to_h  #=> { "lib/commands/" => 45.2, "spec/unit/" => 30.1 }
  #
  # @!attribute [r] entries
  #   @return [Array<DirstatEntry>] directory statistics in order from git output
  #
  DirstatInfo = Data.define(:entries) do
    # Look up percentage by directory path
    #
    # @param directory [String] the directory path
    # @return [Float, nil] the percentage or nil if not found
    #
    def [](directory)
      entries.find { |e| e.directory == directory }&.percentage
    end

    # Convert to a Hash mapping directory to percentage
    #
    # @return [Hash<String, Float>]
    #
    def to_h
      entries.to_h { |e| [e.directory, e.percentage] }
    end

    # Number of directories in the dirstat
    #
    # @return [Integer]
    #
    def size
      entries.size
    end

    # Check if dirstat is empty
    #
    # @return [Boolean]
    #
    def empty?
      entries.empty?
    end

    # Iterate over entries
    #
    # @yield [DirstatEntry] each entry
    # @return [Enumerator] if no block given
    #
    def each(&block)
      entries.each(&block)
    end

    include Enumerable
  end
end
