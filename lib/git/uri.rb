module URI
  module Git
    class Generic < ::URI::Generic
      def full_url
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
      def owner
        repo.split('/')[0]
      end
      def slug
        repo.split('/')[1]
      end
      def to_s
        str = ''
        str << "#{user}@" if user && !user.empty?
        str << "#{host}:#{repo}"
      end
    end
  end
end
