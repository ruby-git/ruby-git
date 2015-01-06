module Git

  class Base

    module Factories

      # returns a Git::Object of the appropriate type
      # you can also call @git.gtree('tree'), but that's 
      # just for readability.  If you call @git.gtree('HEAD') it will
      # still return a Git::Object::Commit object.  
      #
      # @git.object calls a factory method that will run a rev-parse 
      # on the objectish and determine the type of the object and return 
      # an appropriate object for that type 
      def object(objectish)
        Git::Object.new(self, objectish)
      end
      
      def gtree(objectish)
        Git::Object.new(self, objectish, 'tree')
      end
      
      def gcommit(objectish)
        Git::Object.new(self, objectish, 'commit')
      end
      
      def gblob(objectish)
        Git::Object.new(self, objectish, 'blob')
      end
      
      # returns a Git::Log object with count commits
      def log(count = 30)
        Git::Log.new(self, count)
      end
  
      # returns a Git::Status object
      def status
        Git::Status.new(self)
      end
          
      # returns a Git::Branches object of all the Git::Branch objects for this repo
      def branches
        Git::Branches.new(self)
      end
      
      # returns a Git::Branch object for branch_name
      def branch(branch_name = 'master')
        Git::Branch.new(self, branch_name)
      end

    end

  end

end
