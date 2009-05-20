module Git

  # object that holds all available submodules
  class Submodules
    include Enumerable

    def initialize(base)
      @submodules = {}

      @base = base

      @base.lib.submodule_status.split('\n').each do |status|
        s = status.match(Submodule::STATUS_MATCH)
        if s
          @submodules[s[3]] = Git::Submodule.new(@base, s[3])
        end
      end
    end

    # array like methods

    def size
      @submodules.size
    end

    def each(&block)
      @submodules.values.each(&block)
    end

    def [](symbol)
      @submodules[symbol.to_s]
    end

    def to_s
      out = ''
      @submodules.each do |k, s|
        out << s.status
      end
      out
    end

  end
end
