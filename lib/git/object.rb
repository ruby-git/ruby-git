# frozen_string_literal: true

require 'git/author'
require 'git/diff'
require 'git/errors'
require 'git/log'

module Git
  # represents a git object
  class Object
    # A base class for all Git objects
    #
    # @api private
    #
    class AbstractObject
      # @return [String] the object name, SHA, ref, or treeish path
      #
      attr_accessor :objectish

      # @return [String, nil] the git object type
      #
      attr_accessor :type

      # @return [String, nil] the file mode from tree listings
      #
      attr_accessor :mode

      # Sets the size of the git object in bytes
      #
      # @example Set the size to 60 bytes
      #   object.size = 60
      #
      # @return [Integer] the size of the git object in bytes
      #
      attr_writer :size

      # Creates a lazy wrapper for a git object
      #
      # @param base [Git::Repository] the repository used to query object data
      #
      # @param objectish [String, #to_s] the object name, SHA, ref, or treeish path
      #
      def initialize(base, objectish)
        @base = base
        @objectish = objectish.to_s
        @contents = nil
        @trees = nil
        @size = nil
        @sha = nil
      end

      # Returns the resolved SHA for this object
      #
      # @return [String] the resolved object SHA
      #
      def sha
        @sha ||= object_repository.rev_parse(@objectish)
      end

      # Returns the size of this object in bytes
      #
      # @return [Integer] the object size in bytes
      #
      def size
        @size ||= object_repository.cat_file_size(@objectish)
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
          object_repository.cat_file_contents(@objectish, &)
        else
          @contents ||= object_repository.cat_file_contents(@objectish)
        end
      end

      # Returns the object contents split into lines
      #
      # @return [Array<String>] the raw contents split on newline boundaries
      #
      def contents_array
        contents.split("\n")
      end

      # Returns the original object expression
      #
      # @return [String] the object name, SHA, ref, or treeish path
      #
      def to_s
        @objectish
      end

      # Searches this object for matching tracked file contents
      #
      # Always searches this object's resolved SHA. A caller-provided `:object`
      # option is ignored.
      #
      # @param string [String] the pattern to search for
      #
      # @param path_limiter [String, Pathname, Array<String, Pathname>, nil]
      #   path or paths to limit the search to
      #
      # @param opts [Hash] additional grep options
      #
      # @option opts [Boolean, nil] :ignore_case (nil) ignore case
      #   distinctions in the pattern and file contents
      #
      #   Alias: :i
      #
      # @option opts [Boolean, nil] :invert_match (nil) select non-matching
      #   lines
      #
      #   Alias: :v
      #
      # @option opts [Boolean, nil] :extended_regexp (nil) use POSIX extended
      #   regular expressions for the pattern
      #
      #   Alias: :E
      #
      # @return [Hash<String, Array<Array(Integer, String)>>] matching lines by path
      #
      def grep(string, path_limiter = nil, opts = {})
        object_repository.grep(string, path_limiter, opts.merge(object: sha))
      end

      # Returns a diff from this object to another object
      #
      # @param objectish [String] the object name, SHA, ref, or treeish path to diff
      #   against
      #
      # @return [Git::Diff] the diff between the two objects
      #
      def diff(objectish)
        Git::Diff.new(@base, @objectish, objectish)
      end

      # Returns a log scoped to this object
      #
      # @param count [Integer] maximum number of commits to include
      #
      # @return [Git::Log] the scoped log object
      #
      def log(count = 30)
        Git::Log.new(@base, count).object(@objectish)
      end

      # Creates an archive of this object and writes it to a file
      #
      # @example Archive a tree to a zip file
      #   git.object('v1.0').archive('/tmp/release.zip', format: 'zip')
      #
      # @example Archive a tree to a temporary tar file
      #   git.object('v2.6').archive(nil, format: 'tar')
      #
      # @example Archive a tree to a tgz file with a path prefix
      #   git.object('v2.6').archive('/tmp/release.tgz', format: 'tgz', prefix: 'test/')
      #
      # @example Archive one directory with a path prefix
      #   git.object('v2.6').archive(
      #     '/tmp/ex-dir.tar',
      #     format: 'tar',
      #     prefix: 'test/',
      #     path: 'ex_dir/'
      #   )
      #
      # @param file [String, nil] destination file path; a temp file is created if `nil`
      #
      # @param opts [Hash] archive options (see {Git::Repository#archive})
      #
      # @option opts [String] :format ('zip') archive format: `'tar'`, `'zip'`,
      #   or `'tgz'`
      #
      # @option opts [String] :prefix (nil) prefix prepended to every filename
      #   in the archive
      #
      # @option opts [String] :path (nil) path within the tree to include
      #
      # @option opts [String] :remote (nil) retrieve the archive from a remote
      #   repository
      #
      # @option opts [Boolean, nil] :add_gzip (nil) apply gzip compression after
      #   writing the archive
      #
      # @return [String] the path to the written archive file
      #
      # @raise [ArgumentError] when archive options or destination path are invalid
      #
      # @raise [Git::FailedError] if `git archive` fails
      #
      # @api public
      #
      def archive(file = nil, opts = {})
        object_repository.archive(@objectish, file, opts)
      end

      # Returns whether this object is a tree
      #
      # @return [Boolean] `true` when this object is a tree
      #
      def tree? = false

      # Returns whether this object is a blob
      #
      # @return [Boolean] `true` when this object is a blob
      #
      def blob? = false

      # Returns whether this object is a commit
      #
      # @return [Boolean] `true` when this object is a commit
      #
      def commit? = false

      # Returns whether this object is a tag
      #
      # @return [Boolean] `true` when this object is a tag
      #
      def tag? = false

      private

      # @return [Git::Repository] the repository used for object lookup
      #
      def object_repository
        @base
      end
    end

    # A Git blob object
    class Blob < AbstractObject
      # Creates a blob object wrapper
      #
      # @param base [Git::Repository] the repository used to query object data
      #
      # @param sha [String] the blob SHA or object expression
      #
      # @param mode [String, nil] the file mode from tree listings
      #
      def initialize(base, sha, mode = nil)
        super(base, sha)
        @mode = mode
      end

      # Returns whether this object is a blob
      #
      # @return [Boolean] `true`
      #
      def blob?
        true
      end
    end

    # A Git tree object
    class Tree < AbstractObject
      # Creates a tree object wrapper
      #
      # @param base [Git::Repository] the repository used to query object data
      #
      # @param sha [String] the tree SHA or object expression
      #
      # @param mode [String, nil] the file mode from tree listings
      #
      def initialize(base, sha, mode = nil)
        super(base, sha)
        @mode = mode
        @trees = nil
        @blobs = nil
      end

      # Returns child blobs and subtrees keyed by name
      #
      # @return [Hash<String, Git::Object::AbstractObject>] child objects by name
      #
      def children
        blobs.merge(subtrees)
      end

      # Returns blobs directly under this tree
      #
      # @return [Hash<String, Git::Object::Blob>] blob objects by filename
      #
      def blobs
        @blobs ||= check_tree[:blobs]
      end
      alias files blobs

      # Returns subtrees directly under this tree
      #
      # @return [Hash<String, Git::Object::Tree>] subtree objects by directory name
      #
      def trees
        @trees ||= check_tree[:trees]
      end
      alias subtrees trees
      alias subdirectories trees

      # Returns the full tree listing for this tree
      #
      # @return [Hash] parsed recursive tree data
      #
      def full_tree
        object_repository.full_tree(@objectish)
      end

      # Returns the maximum depth of this tree
      #
      # @return [Integer] maximum tree depth
      #
      def depth
        object_repository.tree_depth(@objectish)
      end

      # Returns whether this object is a tree
      #
      # @return [Boolean] `true`
      #
      def tree?
        true
      end

      private

      # actually run the git command
      def check_tree
        @trees = {}
        @blobs = {}

        data = object_repository.ls_tree(@objectish)

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
      # Creates a commit object wrapper
      #
      # @param base [Git::Repository] the repository used to query object data
      #
      # @param sha [String] the commit SHA or object expression
      #
      # @param init [Hash, nil] parsed commit data used to initialize eagerly
      #
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

      # Returns the commit message
      #
      # @return [String] the commit message without the trailing newline
      #
      def message
        check_commit
        @message
      end

      # Returns the symbolic name for this commit
      #
      # @return [String] the name produced by `git name-rev`
      #
      def name
        object_repository.name_rev(sha)
      end

      # Returns the tree for this commit
      #
      # @return [Git::Object::Tree] the commit tree
      #
      def gtree
        check_commit
        Tree.new(@base, @tree)
      end

      # Returns the first parent commit
      #
      # @return [Git::Object::Commit, nil] the first parent commit, or `nil`
      #   for a root commit
      #
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

      # Returns the author date
      #
      # @return [Time] the author timestamp
      #
      def author_date
        author.date
      end

      # git author
      def committer
        check_commit
        @committer
      end

      # Returns the committer date
      #
      # @return [Time] the committer timestamp
      #
      def committer_date
        committer.date
      end
      alias date committer_date

      # Returns the diff between this commit and its first parent
      #
      # @return [Git::Diff] the diff from the first parent to this commit
      #
      def diff_parent
        diff(parent)
      end

      # Sets parsed commit data on this commit object
      #
      # @param data [Hash] parsed commit data
      #
      # @return [void]
      #
      # @deprecated use {#from_data} instead
      #
      def set_commit(data) # rubocop:disable Naming/AccessorMethodName
        Git::Deprecation.warn(
          'Git::Object::Commit#set_commit is deprecated and will be removed in a future version. ' \
          'Use #from_data instead.'
        )
        from_data(data)
      end

      # Loads parsed commit data into this commit object
      #
      # @param data [Hash] parsed commit data from `git cat-file commit`
      #
      # @return [void]
      #
      def from_data(data)
        @sha ||= data['sha']
        @committer = Git::Author.new(data['committer'])
        @author = Git::Author.new(data['author'])
        @tree = Git::Object::Tree.new(@base, data['tree'])
        @parents = data['parent'].map { |sha| Git::Object::Commit.new(@base, sha) }
        @message = data['message'].chomp
      end

      # Returns whether this object is a commit
      #
      # @return [Boolean] `true`
      #
      def commit?
        true
      end

      private

      # see if this object has been initialized and do so if not
      def check_commit
        return if @tree

        data = object_repository.cat_file_commit(@objectish)
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
    class Tag < AbstractObject
      # @return [String] the tag name
      #
      attr_accessor :name

      # @overload initialize(base, name)
      #
      #   @param base [Git::Repository] the git repository
      #
      #   @param name [String] the name of the tag
      #
      # @overload initialize(base, sha, name)
      #
      #   @param base [Git::Repository] the git repository
      #
      #   @param sha [String] the SHA of the tag object
      #
      #   @param name [String] the name of the tag
      #
      def initialize(base, sha, name = nil)
        if name.nil?
          name = sha
          sha = base.tag_sha(name)
          raise Git::UnexpectedResultError, "Tag '#{name}' does not exist." if sha == ''
        end

        super(base, sha)

        @name = name
        @annotated = nil
        @loaded = false
      end

      # Returns whether this tag is annotated
      #
      # @return [Boolean] `true` when the tag has an annotated tag object
      #
      def annotated?
        @annotated = @annotated.nil? ? (object_repository.cat_file_type(name) == 'tag') : @annotated
      end

      # Returns the tag message
      #
      # @return [String, nil] the annotated tag message, or `nil` for a
      #   lightweight tag
      #
      def message
        check_tag
        @message
      end

      # Returns whether this object is a tag
      #
      # @return [Boolean] `true`
      #
      def tag?
        true
      end

      # Returns the tagger identity
      #
      # @return [Git::Author, nil] the tagger for an annotated tag, or `nil`
      #   for a lightweight tag
      #
      def tagger
        check_tag
        @tagger
      end

      private

      # Loads annotated tag data when available
      #
      # @return [void]
      #
      def check_tag
        return if @loaded

        if annotated?
          tdata = object_repository.cat_file_tag(@name)
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
    #
    # @param base [Git::Repository] the repository used to query object data
    #
    # @param objectish [String] the object name, SHA, ref, or treeish path
    #
    # @param type [String, nil] object type hint: `blob`, `commit`, or `tree`
    #
    # @param is_tag [Boolean] whether to construct a tag object
    #
    # @return [Git::Object::AbstractObject] the concrete object wrapper
    #
    def self.new(base, objectish, type = nil, is_tag = false) # rubocop:disable Style/OptionalBooleanParameter
      return new_tag(base, objectish) if is_tag

      type ||= object_repository_for(base).cat_file_type(objectish)
      # TODO: why not handle tag case here too?
      klass =
        case type
        when /blob/   then Blob
        when /commit/ then Commit
        when /tree/   then Tree
        end
      klass.new(base, objectish)
    end

    # Creates a tag object through the deprecated factory path
    #
    # @param base [Git::Repository] the repository used to query object data
    #
    # @param objectish [String] the tag name or SHA
    #
    # @return [Git::Object::Tag] the tag object wrapper
    #
    # @deprecated use `Git::Object::Tag.new` instead
    #
    private_class_method def self.new_tag(base, objectish)
      Git::Deprecation.warn('Git::Object.new with is_tag argument is deprecated. Use Git::Object::Tag.new instead.')
      Git::Object::Tag.new(base, objectish)
    end

    # Returns the repository used for object lookup
    #
    # @param base [Git::Repository] the repository to return
    #
    # @return [Git::Repository] the repository used for object lookup
    #
    private_class_method def self.object_repository_for(base)
      base
    end
  end
end
