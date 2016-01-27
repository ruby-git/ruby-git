module URI
  module Git
    class Generic < ::URI::Generic
      def to_s
        str = ''
        str << "#{user}@" if user && !user.empty?
        str << "#{host}:#{path}"
      end
    end
  end
end
