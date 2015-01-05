module Git

  class Config

    attr_writer :binary_path

    attr_accessor :git_ssh

    def initialize
      @binary_path = nil
    end

    def binary_path
      @binary_path || 'git'
    end

  end

end
