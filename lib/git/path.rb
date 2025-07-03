# frozen_string_literal: true

module Git
  class Path
    attr_accessor :path

    def initialize(path, check_path = true)
      path = File.expand_path(path)

      raise ArgumentError, 'path does not exist', [path] if check_path && !File.exist?(path)

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
