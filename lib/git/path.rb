# frozen_string_literal: true

module Git
  # A base class that represents and validates a filesystem path
  #
  # Use for tracking things relevant to a Git repository, such as the working
  # directory or index file.
  #
  class Path
    attr_accessor :path

    def initialize(path, must_exist: true)
      path = File.expand_path(path)

      raise ArgumentError, 'path does not exist', [path] if must_exist && !File.exist?(path)

      @path = path
    end

    def readable?
      File.readable?(@path)
    end

    def writable?
      File.writable?(@path)
    end

    def to_s
      @path
    end
  end
end
