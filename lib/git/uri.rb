module URI
  module Git
    class Generic < ::URI::Generic
      def to_s
        str = ''
        str << "#{user}@" if user && !user.empty?
        str << "#{host}:#{path}"
      end
      def branch
        path.split('/branch/')[1] || 'master'
      end
      def repo
        path.split('/branch/')[0]
      end
      def to_repo_s
        str = ''
        str << "#{user}@" if user && !user.empty?
        str << "#{host}:#{repo}"
      end
    end
  end
end
