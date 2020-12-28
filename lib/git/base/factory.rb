module Git

  class Base

    module Factory

      # @return [Git::Branch] an object for branch_name
      def branch(branch_name = 'master')
        Git::Branch.new(self, branch_name)
      end

      # @return [Git::Branches] a collection of all the branches in the repository.
      #   Each branch is represented as a {Git::Branch}.
      def branches
        Git::Branches.new(self)
      end

      # returns a Git::Worktree object for dir, commitish
      def worktree(dir, commitish = nil)
        Git::Worktree.new(self, dir, commitish)
      end

      # returns a Git::worktrees object of all the Git::Worktrees
      # objects for this repo
      def worktrees
        Git::Worktrees.new(self)
      end

      # @return [Git::Object::Commit] a commit object
      def commit_tree(tree = nil, opts = {})
        Git::Object::Commit.new(self, self.lib.commit_tree(tree, opts))
      end

      # @return [Git::Diff] a Git::Diff object
      def diff(objectish = 'HEAD', obj2 = nil)
        Git::Diff.new(self, objectish, obj2)
      end

      # @return [Git::Object] a Git object
      def gblob(objectish)
        Git::Object.new(self, objectish, 'blob')
      end

      # @return [Git::Object] a Git object
      def gcommit(objectish)
        Git::Object.new(self, objectish, 'commit')
      end

      # @return [Git::Object] a Git object
      def gtree(objectish)
        Git::Object.new(self, objectish, 'tree')
      end

      # @return [Git::Log] a log with the specified number of commits
      def log(count = 30)
        Git::Log.new(self, count)
      end

      # returns a Git::Object of the appropriate type
      # you can also call @git.gtree('tree'), but that's
      # just for readability.  If you call @git.gtree('HEAD') it will
      # still return a Git::Object::Commit object.
      #
      # object calls a factory method that will run a rev-parse
      # on the objectish and determine the type of the object and return
      # an appropriate object for that type
      #
      # @return [Git::Object] an instance of the appropriate type of Git::Object
      def object(objectish)
        Git::Object.new(self, objectish)
      end

      # @return [Git::Remote] a remote of the specified name
      def remote(remote_name = 'origin')
        Git::Remote.new(self, remote_name)
      end

      # @return [Git::Status] a status object
      def status
        Git::Status.new(self)
      end

      # @return [Git::Object::Tag] a tag object
      def tag(tag_name)
        Git::Object.new(self, tag_name, 'tag', true)
      end

      # Find as good common ancestors as possible for a merge
      # example: g.merge_base('master', 'some_branch', 'some_sha', octopus: true)
      #
      # @return [Array<Git::Object::Commit>] a collection of common ancestors
      def merge_base(*args)
        shas = self.lib.merge_base(*args)
        shas.map { |sha| gcommit(sha) }
      end

    end

  end

end
