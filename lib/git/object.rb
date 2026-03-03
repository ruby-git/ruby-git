# frozen_string_literal: true

require 'git/author'
require 'git/diff'
require 'git/errors'
require 'git/log'

module Git
  # represents a git object
  class Object
    # A base class for all Git objects
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

      # Returns the raw content of this git object or streams it into a temporary file
      #
      # Without a block, the full content is buffered in memory and cached, then
      # returned as a `String`. With a block, git output is streamed directly to a
      # temporary file on disk — suitable for large objects.
      #
      # @api public
      #
      # @overload contents
      #   Returns the cached content as a string.
      #
      #   @return [String] the raw content of the object, cached after first call
      #
      #   @raise [Git::FailedError] if the object does not exist or the command fails
      #
      #   @example Get the contents of a blob
      #     git.object('HEAD:README.md').contents # => "This is a README file\n"
      #
      # @overload contents(&block)
      #   Streams the content to a temporary file and yields it.
      #
      #   Git output is written directly to a file without buffering in
      #   memory. Use this form for large blobs to avoid memory pressure.
      #
      #   @yield [file] the temporary file, positioned at the start of the content
      #
      #   @yieldparam file [File] readable `IO` object positioned at the beginning
      #
      #   @yieldreturn [Object] the value to return from this method
      #
      #   @return [Object] the value returned by the block
      #
      #   @raise [Git::FailedError] if the object does not exist or the command fails
      #
      #   @example Read a large blob without loading it into memory
      #     git.object('HEAD:large_file.bin').contents { |f| upload(f) }
      #
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

      # Creates an archive of this object and writes it to a file
      #
      # @api public
      #
      # @param file [String, nil] destination file path; a temp file is created if `nil`
      #
      # @param opts [Hash] archive options (see {Git::Lib#archive})
      #
      # @return [String] the path to the written archive file
      #
      # @raise [Git::FailedError] if `git archive` fails
      #
      # @example Archive a tree to a zip file
      #   git.object('v1.0').archive('/tmp/release.zip', format: 'zip')
      #
      def archive(file = nil, opts = {})
        @base.lib.archive(@objectish, file, opts)
      end

      def tree? = false

      def blob? = false

      def commit? = false

      def tag? = false
    end

    # A Git blob object
    class Blob < AbstractObject
      def initialize(base, sha, mode = nil)
        super(base, sha)
        @mode = mode
      end

      def blob?
        true
      end
    end

    # A Git tree object
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

        { trees: @trees, blobs: @blobs }
      end
    end

    # A Git commit object
    class Commit < AbstractObject
      def initialize(base, sha, init = nil)
        super(base, sha)
        @tree = nil
        @parents = nil
        @author = nil
        @committer = nil
        @message = nil
        return unless init

        from_data(init)
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

      def set_commit(data) # rubocop:disable Naming/AccessorMethodName
        Git::Deprecation.warn(
          'Git::Object::Commit#set_commit is deprecated and will be removed in a future version. ' \
          'Use #from_data instead.'
        )
        from_data(data)
      end

      def from_data(data)
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
        from_data(data)
      end
    end

    # A Git tag object
    #
    # This class represents a tag in Git, which can be either annotated or lightweight.
    #
    # Annotated tags contain additional metadata such as the tagger's name, email, and
    # the date when the tag was created, along with a message.
    #
    # TODO: Annotated tags are not objects
    #
    class Tag < AbstractObject
      attr_accessor :name

      # @overload initialize(base, name)
      #   @param base [Git::Base] The Git base object
      #   @param name [String] The name of the tag
      #
      # @overload initialize(base, sha, name)
      #   @param base [Git::Base] The Git base object
      #   @param sha [String] The SHA of the tag object
      #   @param name [String] The name of the tag
      #
      def initialize(base, sha, name = nil)
        if name.nil?
          name = sha
          sha = base.lib.tag_sha(name)
          raise Git::UnexpectedResultError, "Tag '#{name}' does not exist." if sha == ''
        end

        super(base, sha)

        @name = name
        @annotated = nil
        @loaded = false
      end

      def annotated?
        @annotated = @annotated.nil? ? (@base.lib.cat_file_type(name) == 'tag') : @annotated
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
    def self.new(base, objectish, type = nil, is_tag = false) # rubocop:disable Style/OptionalBooleanParameter
      return new_tag(base, objectish) if is_tag

      type ||= base.lib.cat_file_type(objectish)
      # TODO: why not handle tag case here too?
      klass =
        case type
        when /blob/   then Blob
        when /commit/ then Commit
        when /tree/   then Tree
        end
      klass.new(base, objectish)
    end

    private_class_method def self.new_tag(base, objectish)
      Git::Deprecation.warn('Git::Object.new with is_tag argument is deprecated. Use Git::Object::Tag.new instead.')
      Git::Object::Tag.new(base, objectish)
    end
  end
end
