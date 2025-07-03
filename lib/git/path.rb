# frozen_string_literal: true

module Git
  # A base class that represents and validates a filesystem path
  #
  # Use for tracking things relevant to a Git repository, such as the working
  # directory or index file.
  #
  class Path
    attr_accessor :path

    def initialize(path, check_path = nil, must_exist: nil)
      Git::Deprecation.warn('The "check_path" argument is deprecated and will be removed in a future version. Use "must_exist:" instead.') unless check_path.nil?

      # default is true
      must_exist = must_exist.nil? && check_path.nil? ? true : must_exist || check_path

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
