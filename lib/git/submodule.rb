module Git
  class Submodule < Path

    STATUS_MATCH = /(^.)(\w*?)\s(.*?)\s?(\(.*\))?$/

    attr_accessor :path, :description, :commitish

    def initialize(base, path)
      @path = path
      @base = base
      set_with_status(self.status)
    end

    def to_s
      @path
    end

    def status
      @base.lib.submodule_status(@path)
    end

    def init
      @base.lib.submodule_init(@path)
      set_with_status(self.status)
    end

    def update
      @base.lib.submodule_update(@path)
      set_with_status(self.status)
    end

    def initialized?
      @state != '-'
    end

    def updated?
      @state == ' '
    end

    def uri
      self.init unless self.initialized?
      @base.config("submodule.#{path}.url")
    end

    def repository
      Git.open(File.join(@base.dir.to_s, self.path))
    end

    private

    def set_with_status(status)
      status = status.match(STATUS_MATCH)
      if status && 5 == status.size && path == status[3]
        @state = status[1]
        @commitish = status[2]
        @description = status[4]
      else
        raise 'Submodule not found'
      end
    end

  end
end
