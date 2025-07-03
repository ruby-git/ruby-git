# frozen_string_literal: true

require 'git/author'
require 'git/diff'
require 'git/errors'
require 'git/log'

module Git
  # represents a git object
  class Object
    class AbstractObject
      attr_accessor :objectish, :type, :mode

      attr_writer :size

      def initialize(base, objectish)
        @base = base
        @objectish = objectish.to_s
        @contents = nil
        @trees = nil
        @size = nil
        @sha = nil
      end

      def sha
        @sha ||= @base.lib.rev_parse(@objectish)
      end

      def size
        @size ||= @base.lib.cat_file_size(@objectish)
      end

      # Get the object's contents.
      # If no block is given, the contents are cached in memory and returned as a string.
      # If a block is given, it yields an IO object (via IO::popen) which could be used to
      # read a large file in chunks.
      #
      # Use this for large files so that they are not held in memory.
      def contents(&)
        if block_given?
          @base.lib.cat_file_contents(@objectish, &)
        else
          @contents ||= @base.lib.cat_file_contents(@objectish)
        end
      end

      def contents_array
        contents.split("\n")
      end

      def to_s
        @objectish
      end

      def grep(string, path_limiter = nil, opts = {})
        opts = { object: sha, path_limiter: path_limiter }.merge(opts)
        @base.lib.grep(string, opts)
      end

      def diff(objectish)
        Git::Diff.new(@base, @objectish, objectish)
      end

      def log(count = 30)
        Git::Log.new(@base, count).object(@objectish)
      end

      # creates an archive of this object (tree)
      def archive(file = nil, opts = {})
        @base.lib.archive(@objectish, file, opts)
      end

      def tree? = false

      def blob? = false

      def commit? = false

      def tag? = false
    end

    class Blob < AbstractObject
      def initialize(base, sha, mode = nil)
        super(base, sha)
        @mode = mode
      end

      def blob?
        true
      end
    end

    class Tree < AbstractObject
      def initialize(base, sha, mode = nil)
        super(base, sha)
        @mode = mode
        @trees = nil
        @blobs = nil
      end

      def children
        blobs.merge(subtrees)
      end

      def blobs
        @blobs ||= check_tree[:blobs]
      end
      alias files blobs

      def trees
        @trees ||= check_tree[:trees]
      end
      alias subtrees trees
      alias subdirectories trees

      def full_tree
        @base.lib.full_tree(@objectish)
      end

      def depth
        @base.lib.tree_depth(@objectish)
      end

      def tree?
        true
      end

      private

      # actually run the git command
      def check_tree
        @trees = {}
        @blobs = {}

        data = @base.lib.ls_tree(@objectish)

        data['tree'].each do |key, tree|
          @trees[key] = Git::Object::Tree.new(@base, tree[:sha], tree[:mode])
        end

        data['blob'].each do |key, blob|
          @blobs[key] = Git::Object::Blob.new(@base, blob[:sha], blob[:mode])
        end

        {
          trees: @trees,
          blobs: @blobs
        }
      end
    end

    class Commit < AbstractObject
      def initialize(base, sha, init = nil)
        super(base, sha)
        @tree = nil
        @parents = nil
        @author = nil
        @committer = nil
        @message = nil
        return unless init

        set_commit(init)
      end

      def message
        check_commit
        @message
      end

      def name
        @base.lib.name_rev(sha)
      end

      def gtree
        check_commit
        Tree.new(@base, @tree)
      end

      def parent
        parents.first
      end

      # array of all parent commits
      def parents
        check_commit
        @parents
      end

      # git author
      def author
        check_commit
        @author
      end

      def author_date
        author.date
      end

      # git author
      def committer
        check_commit
        @committer
      end

      def committer_date
        committer.date
      end
      alias date committer_date

      def diff_parent
        diff(parent)
      end

      def set_commit(data)
        @sha ||= data['sha']
        @committer = Git::Author.new(data['committer'])
        @author = Git::Author.new(data['author'])
        @tree = Git::Object::Tree.new(@base, data['tree'])
        @parents = data['parent'].map { |sha| Git::Object::Commit.new(@base, sha) }
        @message = data['message'].chomp
      end

      def commit?
        true
      end

      private

      # see if this object has been initialized and do so if not
      def check_commit
        return if @tree

        data = @base.lib.cat_file_commit(@objectish)
        set_commit(data)
      end
    end

    class Tag < AbstractObject
      attr_accessor :name

      def initialize(base, sha, name)
        super(base, sha)
        @name = name
        @annotated = nil
        @loaded = false
      end

      def annotated?
        @annotated ||= (@base.lib.cat_file_type(name) == 'tag')
      end

      def message
        check_tag
        @message
      end

      def tag?
        true
      end

      def tagger
        check_tag
        @tagger
      end

      private

      def check_tag
        return if @loaded

        if annotated?
          tdata = @base.lib.cat_file_tag(@name)
          @message = tdata['message'].chomp
          @tagger = Git::Author.new(tdata['tagger'])
        else
          @message = @tagger = nil
        end

        @loaded = true
      end
    end

    # if we're calling this, we don't know what type it is yet
    # so this is our little factory method
    def self.new(base, objectish, type = nil, is_tag = false)
      if is_tag
        sha = base.lib.tag_sha(objectish)
        raise Git::UnexpectedResultError.new("Tag '#{objectish}' does not exist.") if sha == ''

        return Git::Object::Tag.new(base, sha, objectish)
      end

      type ||= base.lib.cat_file_type(objectish)
      klass =
        case type
        when /blob/   then Blob
        when /commit/ then Commit
        when /tree/   then Tree
        end
      klass.new(base, objectish)
    end
  end
end
