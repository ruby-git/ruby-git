# frozen_string_literal: true

require 'git/command_line'
require 'git/errors'
require 'logger'
require 'pp'
require 'process_executer'
require 'stringio'
require 'tempfile'
require 'zlib'
require 'open3'

module Git
  # Internal git operations
  # @api private
  class Lib
    # The path to the Git working copy.  The default is '"./.git"'.
    #
    # @return [Pathname] the path to the Git working copy.
    #
    # @see [Git working tree](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefworkingtreeaworkingtree)
    #
    attr_reader :git_work_dir

    # The path to the Git repository directory.  The default is
    # `"#{git_work_dir}/.git"`.
    #
    # @return [Pathname] the Git repository directory.
    #
    # @see [Git repository](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefrepositoryarepository)
    #
    attr_reader :git_dir

    # The Git index file used to stage changes (using `git add`) before they
    # are committed.
    #
    # @return [Pathname] the Git index file
    #
    # @see [Git index file](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefindexaindex)
    #
    attr_reader :git_index_file

    # Create a new Git::Lib object
    #
    # @overload initialize(base, logger)
    #
    #   @param base [Hash] the hash containing paths to the Git working copy,
    #     the Git repository directory, and the Git index file.
    #
    #   @option base [Pathname] :working_directory
    #   @option base [Pathname] :repository
    #   @option base [Pathname] :index
    #
    #   @param [Logger] logger
    #
    # @overload initialize(base, logger)
    #
    #   @param base [#dir, #repo, #index] an object with methods to get the Git worktree (#dir),
    #     the Git repository directory (#repo), and the Git index file (#index).
    #
    #   @param [Logger] logger
    #
    def initialize(base = nil, logger = nil)
      @logger = logger || Logger.new(nil)

      case base
      when Git::Base
        initialize_from_base(base)
      when Hash
        initialize_from_hash(base)
      end
    end

    # creates or reinitializes the repository
    #
    # options:
    #   :bare
    #   :working_directory
    #   :initial_branch
    #
    def init(opts = {})
      arr_opts = []
      arr_opts << '--bare' if opts[:bare]
      arr_opts << "--initial-branch=#{opts[:initial_branch]}" if opts[:initial_branch]

      command('init', *arr_opts)
    end

    # Clones a repository into a newly created directory
    #
    # @param [String] repository_url the URL of the repository to clone
    #
    # @param [String, nil] directory the directory to clone into
    #
    #   If nil, the repository is cloned into a directory with the same name as
    #   the repository.
    #
    # @param [Hash] opts the options for this command
    #
    # @option opts [Boolean] :bare (false) if true, clone as a bare repository
    #
    # @option opts [String] :branch the branch to checkout
    #
    # @option opts [String, Array] :config one or more configuration options to set
    #
    # @option opts [Integer] :depth the number of commits back to pull
    #
    # @option opts [String] :filter specify partial clone
    #
    # @option opts [String] :mirror set up a mirror of the source repository
    #
    # @option opts [String] :origin the name of the remote
    #
    # @option opts [String] :path an optional prefix for the directory parameter
    #
    # @option opts [String] :remote the name of the remote
    #
    # @option opts [Boolean] :recursive after the clone is created, initialize all
    #    within, using their default settings
    #
    # @option opts [Numeric, nil] :timeout the number of seconds to wait for the
    #   command to complete
    #
    #   See {Git::Lib#command} for more information about :timeout
    #
    # @return [Hash] the options to pass to {Git::Base.new}
    #
    # @todo make this work with SSH password or auth_key
    #
    def clone(repository_url, directory, opts = {})
      @path = opts[:path] || '.'
      clone_dir = opts[:path] ? File.join(@path, directory) : directory

      args = build_clone_args(repository_url, clone_dir, opts)
      command('clone', *args, timeout: opts[:timeout])

      return_base_opts_from_clone(clone_dir, opts)
    end

    # Returns the name of the default branch of the given repository
    #
    # @param repository [URI, Pathname, String] The (possibly remote) repository to clone from
    #
    # @return [String] the name of the default branch
    #
    def repository_default_branch(repository)
      output = command('ls-remote', '--symref', '--', repository, 'HEAD')

      match_data = output.match(%r{^ref: refs/remotes/origin/(?<default_branch>[^\t]+)\trefs/remotes/origin/HEAD$})
      return match_data[:default_branch] if match_data

      match_data = output.match(%r{^ref: refs/heads/(?<default_branch>[^\t]+)\tHEAD$})
      return match_data[:default_branch] if match_data

      raise Git::UnexpectedResultError, 'Unable to determine the default branch'
    end

    ## READ COMMANDS ##

    # Finds most recent tag that is reachable from a commit
    #
    # @see https://git-scm.com/docs/git-describe git-describe
    #
    # @param commit_ish [String, nil] target commit sha or object name
    #
    # @param opts [Hash] the given options
    #
    # @option opts :all [Boolean]
    # @option opts :tags [Boolean]
    # @option opts :contains [Boolean]
    # @option opts :debug [Boolean]
    # @option opts :long [Boolean]
    # @option opts :always [Boolean]
    # @option opts :exact_match [Boolean]
    # @option opts :dirty [true, String]
    # @option opts :abbrev [String]
    # @option opts :candidates [String]
    # @option opts :match [String]
    #
    # @return [String] the tag name
    #
    # @raise [ArgumentError] if the commit_ish is a string starting with a hyphen
    #
    def describe(commit_ish = nil, opts = {})
      assert_args_are_not_options('commit-ish object', commit_ish)

      args = build_describe_boolean_opts(opts)
      args += build_describe_valued_opts(opts)
      args += build_describe_dirty_opt(opts)
      args << commit_ish if commit_ish

      command('describe', *args)
    end

    # Return the commits that are within the given revision range
    #
    # @see https://git-scm.com/docs/git-log git-log
    #
    # @param opts [Hash] the given options
    #
    # @option opts :count [Integer] the maximum number of commits to return (maps to max-count)
    # @option opts :all [Boolean]
    # @option opts :cherry [Boolean]
    # @option opts :since [String]
    # @option opts :until [String]
    # @option opts :grep [String]
    # @option opts :author [String]
    # @option opts :between [Array<String>] an array of two commit-ish strings to specify a revision range
    #
    #   Only :between or :object options can be used, not both.
    #
    # @option opts :object [String] the revision range for the git log command
    #
    #   Only :between or :object options can be used, not both.
    #
    # @option opts :path_limiter [Array<String>, String] only include commits that impact files from the specified paths
    #
    # @return [Array<String>] the log output
    #
    # @raise [ArgumentError] if the resulting revision range is a string starting with a hyphen
    #
    def log_commits(opts = {})
      assert_args_are_not_options('between', opts[:between]&.first)
      assert_args_are_not_options('object', opts[:object])

      arr_opts = log_common_options(opts)

      arr_opts << '--pretty=oneline'

      arr_opts += log_path_options(opts)

      command_lines('log', *arr_opts).map { |l| l.split.first }
    end

    # Return the commits that are within the given revision range
    #
    # @see https://git-scm.com/docs/git-log git-log
    #
    # @param opts [Hash] the given options
    #
    # @option opts :count [Integer] the maximum number of commits to return (maps to
    #   max-count)
    #
    # @option opts :all [Boolean]
    #
    # @option opts :cherry [Boolean]
    #
    # @option opts :since [String]
    #
    # @option opts :until [String]
    #
    # @option opts :grep [String]
    #
    # @option opts :author [String]
    #
    # @option opts :between [Array<String>] an array of two commit-ish strings to
    #   specify a revision range
    #
    #   Only :between or :object options can be used, not both.
    #
    # @option opts :object [String] the revision range for the git log command
    #
    #   Only :between or :object options can be used, not both.
    #
    # @option opts :path_limiter [Array<String>, String] only include commits that
    #   impact files from the specified paths
    #
    # @option opts :skip [Integer]
    #
    # @return [Array<Hash>] the log output parsed into an array of hashs for each commit
    #
    #   Each hash contains the following keys:
    #
    #   * 'sha' [String] the commit sha
    #   * 'author' [String] the author of the commit
    #   * 'message' [String] the commit message
    #   * 'parent' [Array<String>] the commit shas of the parent commits
    #   * 'tree' [String] the tree sha
    #   * 'author' [String] the author of the commit and timestamp of when the
    #     changes were created
    #   * 'committer' [String] the committer of the commit and timestamp of when the
    #     commit was applied
    #   * 'merges' [Boolean] if truthy, only include merge commits (aka commits with
    #     2 or more parents)
    #
    # @raise [ArgumentError] if the revision range (specified with :between or
    #   :object) is a string starting with a hyphen
    #
    def full_log_commits(opts = {})
      assert_args_are_not_options('between', opts[:between]&.first)
      assert_args_are_not_options('object', opts[:object])

      arr_opts = log_common_options(opts)

      arr_opts << '--pretty=raw'
      arr_opts << "--skip=#{opts[:skip]}" if opts[:skip]
      arr_opts << '--merges' if opts[:merges]

      arr_opts += log_path_options(opts)

      full_log = command_lines('log', *arr_opts)

      process_commit_log_data(full_log)
    end

    # Verify and resolve a Git revision to its full SHA
    #
    # @see https://git-scm.com/docs/git-rev-parse git-rev-parse
    # @see https://git-scm.com/docs/git-rev-parse#_specifying_revisions Valid ways to specify revisions
    # @see https://git-scm.com/docs/git-rev-parse#Documentation/git-rev-parse.txt-emltrefnamegtemegemmasterememheadsmasterememrefsheadsmasterem
    #      Ref disambiguation rules
    #
    # @example
    #   lib.rev_parse('HEAD') # => '9b9b31e704c0b85ffdd8d2af2ded85170a5af87d'
    #   lib.rev_parse('9b9b31e') # => '9b9b31e704c0b85ffdd8d2af2ded85170a5af87d'
    #
    # @param revision [String] the revision to resolve
    #
    # @return [String] the full commit hash
    #
    # @raise [Git::FailedError] if the revision cannot be resolved
    # @raise [ArgumentError] if the revision is a string starting with a hyphen
    #
    def rev_parse(revision)
      assert_args_are_not_options('rev', revision)

      command('rev-parse', '--revs-only', '--end-of-options', revision, '--')
    end

    # For backwards compatibility with the old method name
    alias revparse rev_parse

    # Find the first symbolic name for given commit_ish
    #
    # @param commit_ish [String] the commit_ish to find the symbolic name of
    #
    # @return [String, nil] the first symbolic name or nil if the commit_ish isn't found
    #
    # @raise [ArgumentError] if the commit_ish is a string starting with a hyphen
    #
    def name_rev(commit_ish)
      assert_args_are_not_options('commit_ish', commit_ish)

      command('name-rev', commit_ish).split[1]
    end

    alias namerev name_rev

    # Output the contents or other properties of one or more objects.
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file
    #
    # @example Get the contents of a file without a block
    #   lib.cat_file_contents('README.md') # => "This is a README file\n"
    #
    # @example Get the contents of a file with a block
    #  lib.cat_file_contents('README.md') { |f| f.read } # => "This is a README file\n"
    #
    # @param object [String] the object whose contents to return
    #
    # @return [String] the object contents
    #
    # @raise [ArgumentError] if object is a string starting with a hyphen
    #
    def cat_file_contents(object)
      assert_args_are_not_options('object', object)

      if block_given?
        Tempfile.create do |file|
          # If a block is given, write the output from the process to a temporary
          # file and then yield the file to the block
          #
          command('cat-file', '-p', object, out: file, err: file)
          file.rewind
          yield file
        end
      else
        # If a block is not given, return the file contents as a string
        command('cat-file', '-p', object)
      end
    end

    alias object_contents cat_file_contents

    # Get the type for the given object
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file
    #
    # @param object [String] the object to get the type
    #
    # @return [String] the object type
    #
    # @raise [ArgumentError] if object is a string starting with a hyphen
    #
    def cat_file_type(object)
      assert_args_are_not_options('object', object)

      command('cat-file', '-t', object)
    end

    alias object_type cat_file_type

    # Get the size for the given object
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file
    #
    # @param object [String] the object to get the type
    #
    # @return [String] the object type
    #
    # @raise [ArgumentError] if object is a string starting with a hyphen
    #
    def cat_file_size(object)
      assert_args_are_not_options('object', object)

      command('cat-file', '-s', object).to_i
    end

    alias object_size cat_file_size

    # Return a hash of commit data
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file
    #
    # @param object [String] the object to get the type
    #
    # @return [Hash] commit data
    #
    # The returned commit data has the following keys:
    #    * tree [String]
    #    * parent [Array<String>]
    #    * author [String] the author name, email, and commit timestamp
    #    * committer [String] the committer name, email, and merge timestamp
    #    * message [String] the commit message
    #    * gpgsig [String] the public signing key of the commit (if signed)
    #
    # @raise [ArgumentError] if object is a string starting with a hyphen
    #
    def cat_file_commit(object)
      assert_args_are_not_options('object', object)

      cdata = command_lines('cat-file', 'commit', object)
      process_commit_data(cdata, object)
    end

    alias commit_data cat_file_commit

    def process_commit_data(data, sha)
      # process_commit_headers consumes the header lines from the `data` array,
      # leaving only the message lines behind.
      headers = process_commit_headers(data)
      message = "#{data.join("\n")}\n"

      { 'sha' => sha, 'message' => message }.merge(headers)
    end

    CAT_FILE_HEADER_LINE = /\A(?<key>\w+) (?<value>.*)\z/

    def each_cat_file_header(data)
      while (match = CAT_FILE_HEADER_LINE.match(data.shift))
        key = match[:key]
        value_lines = [match[:value]]

        value_lines << data.shift.lstrip while data.first.start_with?(' ')

        yield key, value_lines.join("\n")
      end
    end

    # Return a hash of annotated tag data
    #
    # Does not work with lightweight tags. List all annotated tags in your repository
    # with the following command:
    #
    # ```sh
    # git for-each-ref --format='%(refname:strip=2)' refs/tags | \
    #   while read tag; do git cat-file tag $tag >/dev/null 2>&1 && echo $tag; done
    # ```
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file
    #
    # @param object [String] the tag to retrieve
    #
    # @return [Hash] tag data
    #
    #   Example tag data returned:
    #   ```ruby
    #   {
    #     "name" => "annotated_tag",
    #     "object" => "46abbf07e3c564c723c7c039a43ab3a39e5d02dd",
    #     "type" => "commit",
    #     "tag" => "annotated_tag",
    #     "tagger" => "Scott Chacon <schacon@gmail.com> 1724799270 -0700",
    #     "message" => "Creating an annotated tag\n"
    #   }
    #   ```
    #
    # The returned commit data has the following keys:
    #   * object [String] the sha of the tag object
    #   * type [String]
    #   * tag [String] tag name
    #   * tagger [String] the name and email of the user who created the tag
    #     and the timestamp of when the tag was created
    #   * message [String] the tag message
    #
    # @raise [ArgumentError] if object is a string starting with a hyphen
    #
    def cat_file_tag(object)
      assert_args_are_not_options('object', object)

      tdata = command_lines('cat-file', 'tag', object)
      process_tag_data(tdata, object)
    end

    alias tag_data cat_file_tag

    def process_tag_data(data, name)
      hsh = { 'name' => name }

      each_cat_file_header(data) do |key, value|
        hsh[key] = value
      end

      hsh['message'] = "#{data.join("\n")}\n"

      hsh
    end

    def process_commit_log_data(data)
      RawLogParser.new(data).parse
    end

    # A private parser class to process the output of `git log --pretty=raw`
    # @api private
    class RawLogParser
      def initialize(lines)
        @lines = lines
        @commits = []
        @current_commit = nil
        @in_message = false
      end

      def parse
        @lines.each { |line| process_line(line.chomp) }
        finalize_commit
        @commits
      end

      private

      def process_line(line)
        if line.empty?
          @in_message = !@in_message
          return
        end

        @in_message = false if @in_message && !line.start_with?('    ')

        @in_message ? process_message_line(line) : process_metadata_line(line)
      end

      def process_message_line(line)
        @current_commit['message'] << "#{line[4..]}\n"
      end

      def process_metadata_line(line)
        key, *value = line.split
        value = value.join(' ')

        case key
        when 'commit'
          start_new_commit(value)
        when 'parent'
          @current_commit['parent'] << value
        else
          @current_commit[key] = value
        end
      end

      def start_new_commit(sha)
        finalize_commit
        @current_commit = { 'sha' => sha, 'message' => +'', 'parent' => [] }
      end

      def finalize_commit
        @commits << @current_commit if @current_commit
      end
    end
    private_constant :RawLogParser

    def ls_tree(sha, opts = {})
      data = { 'blob' => {}, 'tree' => {}, 'commit' => {} }

      ls_tree_opts = []
      ls_tree_opts << '-r' if opts[:recursive]
      # path must be last arg
      ls_tree_opts << opts[:path] if opts[:path]

      command_lines('ls-tree', sha, *ls_tree_opts).each do |line|
        (info, filenm) = line.split("\t")
        (mode, type, sha) = info.split
        data[type][filenm] = { mode: mode, sha: sha }
      end

      data
    end

    def mv(file1, file2)
      command_lines('mv', '--', file1, file2)
    end

    def full_tree(sha)
      command_lines('ls-tree', '-r', sha)
    end

    def tree_depth(sha)
      full_tree(sha).size
    end

    def change_head_branch(branch_name)
      command('symbolic-ref', 'HEAD', "refs/heads/#{branch_name}")
    end

    BRANCH_LINE_REGEXP = /
      ^
        # Prefix indicates if this branch is checked out. The prefix is one of:
        (?:
          (?<current>\*[[:blank:]]) |  # Current branch (checked out in the current worktree)
          (?<worktree>\+[[:blank:]]) | # Branch checked out in a different worktree
          [[:blank:]]{2}               # Branch not checked out
        )

        # The branch's full refname
        (?:
          (?<not_a_branch>\(not[[:blank:]]a[[:blank:]]branch\)) |
          (?:\(HEAD[[:blank:]]detached[[:blank:]]at[[:blank:]](?<detached_ref>[^\)]+)\)) |
          (?<refname>[^[[:blank:]]]+)
        )

        # Optional symref
        # If this ref is a symbolic reference, this is the ref referenced
        (?:
          [[:blank:]]->[[:blank:]](?<symref>.*)
        )?
      $
    /x

    def branches_all
      lines = command_lines('branch', '-a')
      lines.each_with_index.filter_map do |line, index|
        parse_branch_line(line, index, lines)
      end
    end

    def worktrees_all
      arr = []
      directory = ''
      # Output example for `worktree list --porcelain`:
      # worktree /code/public/ruby-git
      # HEAD 4bef5abbba073c77b4d0ccc1ffcd0ed7d48be5d4
      # branch refs/heads/master
      #
      # worktree /tmp/worktree-1
      # HEAD b8c63206f8d10f57892060375a86ae911fad356e
      # detached
      #
      command_lines('worktree', 'list', '--porcelain').each do |w|
        s = w.split
        directory = s[1] if s[0] == 'worktree'
        arr << [directory, s[1]] if s[0] == 'HEAD'
      end
      arr
    end

    def worktree_add(dir, commitish = nil)
      return command('worktree', 'add', dir, commitish) unless commitish.nil?

      command('worktree', 'add', dir)
    end

    def worktree_remove(dir)
      command('worktree', 'remove', dir)
    end

    def worktree_prune
      command('worktree', 'prune')
    end

    def list_files(ref_dir)
      dir = File.join(@git_dir, 'refs', ref_dir)
      Dir.glob('**/*', base: dir).select { |f| File.file?(File.join(dir, f)) }
    end

    # The state and name of branch pointed to by `HEAD`
    #
    # HEAD can be in the following states:
    #
    # **:active**: `HEAD` points to a branch reference which in turn points to a
    # commit representing the tip of that branch. This is the typical state when
    # working on a branch.
    #
    # **:unborn**: `HEAD` points to a branch reference that does not yet exist
    # because no commits have been made on that branch. This state occurs in two
    # scenarios:
    #
    # * When a repository is newly initialized, and no commits have been made on the
    #   initial branch.
    # * When a new branch is created using `git checkout --orphan <branch>`, starting
    #   a new branch with no history.
    #
    # **:detached**: `HEAD` points directly to a specific commit (identified by its
    # SHA) rather than a branch reference. This state occurs when you check out a
    # commit, a tag, or any state that is not directly associated with a branch. The
    # branch name in this case is `HEAD`.
    #
    HeadState = Struct.new(:state, :name)

    # The current branch state which is the state of `HEAD`
    #
    # @return [HeadState] the state and name of the current branch
    #
    def current_branch_state
      branch_name = command('branch', '--show-current')
      return HeadState.new(:detached, 'HEAD') if branch_name.empty?

      state = get_branch_state(branch_name)
      HeadState.new(state, branch_name)
    end

    def branch_current
      branch_name = command('branch', '--show-current')
      branch_name.empty? ? 'HEAD' : branch_name
    end

    def branch_contains(commit, branch_name = '')
      command('branch',  branch_name, '--contains', commit)
    end

    # returns hash
    # [tree-ish] = [[line_no, match], [line_no, match2]]
    # [tree-ish] = [[line_no, match], [line_no, match2]]
    def grep(string, opts = {})
      opts[:object] ||= 'HEAD'
      args = build_grep_args(string, opts)
      lines = execute_grep_command(args)
      parse_grep_output(lines)
    end

    # Validate that the given arguments cannot be mistaken for a command-line option
    #
    # @param arg_name [String] the name of the arguments to mention in the error message
    # @param args [Array<String, nil>] the arguments to validate
    #
    # @raise [ArgumentError] if any of the parameters are a string starting with a hyphen
    # @return [void]
    #
    def assert_args_are_not_options(arg_name, *args)
      invalid_args = args.select { |arg| arg&.start_with?('-') }
      return unless invalid_args.any?

      raise ArgumentError, "Invalid #{arg_name}: '#{invalid_args.join("', '")}'"
    end

    def diff_full(obj1 = 'HEAD', obj2 = nil, opts = {})
      assert_args_are_not_options('commit or commit range', obj1, obj2)

      diff_opts = ['-p']
      diff_opts << obj1
      diff_opts << obj2 if obj2.is_a?(String)
      diff_opts << '--' << opts[:path_limiter] if opts[:path_limiter].is_a? String

      command('diff', *diff_opts)
    end

    def diff_stats(obj1 = 'HEAD', obj2 = nil, opts = {})
      assert_args_are_not_options('commit or commit range', obj1, obj2)
      args = build_diff_stats_args(obj1, obj2, opts)
      output_lines = command_lines('diff', *args)
      parse_diff_stats_output(output_lines)
    end

    def diff_path_status(reference1 = nil, reference2 = nil, opts = {})
      assert_args_are_not_options('commit or commit range', reference1, reference2)

      opts_arr = ['--name-status']
      opts_arr << reference1 if reference1
      opts_arr << reference2 if reference2

      opts_arr << '--' << opts[:path] if opts[:path]

      command_lines('diff', *opts_arr).each_with_object({}) do |line, memo|
        status, path = line.split("\t")
        memo[path] = status
      end
    end

    # compares the index and the working directory
    def diff_files
      diff_as_hash('diff-files')
    end

    # compares the index and the repository
    def diff_index(treeish)
      diff_as_hash('diff-index', treeish)
    end

    # List all files that are in the index
    #
    # @param location [String] the location to list the files from
    #
    # @return [Hash<String, Hash>] a hash of files in the index
    #   * key: file [String] the file path
    #   * value: file_info [Hash] the file information containing the following keys:
    #     * :path [String] the file path
    #     * :mode_index [String] the file mode
    #     * :sha_index [String] the file sha
    #     * :stage [String] the file stage
    #
    def ls_files(location = nil)
      location ||= '.'
      {}.tap do |files|
        command_lines('ls-files', '--stage', location).each do |line|
          (info, file) = line.split("\t")
          (mode, sha, stage) = info.split
          files[unescape_quoted_path(file)] = {
            path: file, mode_index: mode, sha_index: sha, stage: stage
          }
        end
      end
    end

    # Unescape a path if it is quoted
    #
    # Git commands that output paths (e.g. ls-files, diff), will escape unusual
    # characters.
    #
    # @example
    #   lib.unescape_if_quoted('"quoted_file_\\342\\230\\240"') # => 'quoted_file_☠'
    #   lib.unescape_if_quoted('unquoted_file')   # => 'unquoted_file'
    #
    # @param path [String] the path to unescape if quoted
    #
    # @return [String] the unescaped path if quoted otherwise the original path
    #
    # @api private
    #
    def unescape_quoted_path(path)
      if path.start_with?('"') && path.end_with?('"')
        Git::EscapedPath.new(path[1..-2]).unescape
      else
        path
      end
    end

    def ls_remote(location = nil, opts = {})
      args = []
      args << '--refs' if opts[:refs]
      args << (location || '.')

      output_lines = command_lines('ls-remote', *args)
      parse_ls_remote_output(output_lines)
    end

    def ignored_files
      command_lines('ls-files', '--others', '-i', '--exclude-standard').map { |f| unescape_quoted_path(f) }
    end

    def untracked_files
      command_lines('ls-files', '--others', '--exclude-standard', chdir: @git_work_dir)
    end

    def config_remote(name)
      hsh = {}
      config_list.each do |key, value|
        hsh[key.gsub("remote.#{name}.", '')] = value if /remote.#{name}/.match(key)
      end
      hsh
    end

    def config_get(name)
      command('config', '--get', name, chdir: @git_dir)
    end

    def global_config_get(name)
      command('config', '--global', '--get', name)
    end

    def config_list
      parse_config_list command_lines('config', '--list', chdir: @git_dir)
    end

    def global_config_list
      parse_config_list command_lines('config', '--global', '--list')
    end

    def parse_config_list(lines)
      hsh = {}
      lines.each do |line|
        (key, *values) = line.split('=')
        hsh[key] = values.join('=')
      end
      hsh
    end

    def parse_config(file)
      parse_config_list command_lines('config', '--list', '--file', file)
    end

    # Shows objects
    #
    # @param [String|NilClass] objectish the target object reference (nil == HEAD)
    # @param [String|NilClass] path the path of the file to be shown
    # @return [String] the object information
    def show(objectish = nil, path = nil)
      arr_opts = []

      arr_opts << (path ? "#{objectish}:#{path}" : objectish)

      command('show', *arr_opts.compact, chomp: false)
    end

    ## WRITE COMMANDS ##

    def config_set(name, value, options = {})
      if options[:file].to_s.empty?
        command('config', name, value)
      else
        command('config', '--file', options[:file], name, value)
      end
    end

    def global_config_set(name, value)
      command('config', '--global', name, value)
    end

    # Update the index from the current worktree to prepare the for the next commit
    #
    # @example
    #   lib.add('path/to/file')
    #   lib.add(['path/to/file1','path/to/file2'])
    #   lib.add(:all => true)
    #
    # @param [String, Array<String>] paths files to be added to the repository (relative to the worktree root)
    # @param [Hash] options
    #
    # @option options [Boolean] :all Add, modify, and remove index entries to match the worktree
    # @option options [Boolean] :force Allow adding otherwise ignored files
    #
    def add(paths = '.', options = {})
      arr_opts = []

      arr_opts << '--all' if options[:all]
      arr_opts << '--force' if options[:force]

      arr_opts << '--'

      arr_opts << paths

      arr_opts.flatten!

      command('add', *arr_opts)
    end

    def rm(path = '.', opts = {})
      arr_opts = ['-f'] # overrides the up-to-date check by default
      arr_opts << '-r' if opts[:recursive]
      arr_opts << '--cached' if opts[:cached]
      arr_opts << '--'
      arr_opts += Array(path)

      command('rm', *arr_opts)
    end

    # Returns true if the repository is empty (meaning it has no commits)
    #
    # @return [Boolean]
    #
    def empty?
      command('rev-parse', '--verify', 'HEAD')
      false
    rescue Git::FailedError => e
      raise unless e.result.status.exitstatus == 128 &&
                   e.result.stderr == 'fatal: Needed a single revision'

      true
    end

    # Takes the commit message with the options and executes the commit command
    #
    # accepts options:
    #  :amend
    #  :all
    #  :allow_empty
    #  :author
    #  :date
    #  :no_verify
    #  :allow_empty_message
    #  :gpg_sign (accepts true or a gpg key ID as a String)
    #  :no_gpg_sign (conflicts with :gpg_sign)
    #
    # @param [String] message the commit message to be used
    # @param [Hash] opts the commit options to be used
    def commit(message, opts = {})
      args = []
      args << "--message=#{message}" if message
      args += build_commit_general_opts(opts)
      args += build_commit_gpg_opts(opts)

      command('commit', *args)
    end

    def reset(commit, opts = {})
      arr_opts = []
      arr_opts << '--hard' if opts[:hard]
      arr_opts << commit if commit
      command('reset', *arr_opts)
    end

    def clean(opts = {})
      arr_opts = []
      arr_opts << '--force' if opts[:force]
      arr_opts << '-ff' if opts[:ff]
      arr_opts << '-d' if opts[:d]
      arr_opts << '-x' if opts[:x]

      command('clean', *arr_opts)
    end

    def revert(commitish, opts = {})
      # Forcing --no-edit as default since it's not an interactive session.
      opts = { no_edit: true }.merge(opts)

      arr_opts = []
      arr_opts << '--no-edit' if opts[:no_edit]
      arr_opts << commitish

      command('revert', *arr_opts)
    end

    def apply(patch_file)
      arr_opts = []
      arr_opts << '--' << patch_file if patch_file
      command('apply', *arr_opts)
    end

    def apply_mail(patch_file)
      arr_opts = []
      arr_opts << '--' << patch_file if patch_file
      command('am', *arr_opts)
    end

    def stashes_all
      stash_log_lines.each_with_index.map do |line, index|
        parse_stash_log_line(line, index)
      end
    end

    def stash_save(message)
      output = command('stash', 'save', message)
      output =~ /HEAD is now at/
    end

    def stash_apply(id = nil)
      if id
        command('stash', 'apply', id)
      else
        command('stash', 'apply')
      end
    end

    def stash_clear
      command('stash', 'clear')
    end

    def stash_list
      command('stash', 'list')
    end

    def branch_new(branch)
      command('branch', branch)
    end

    def branch_delete(branch)
      command('branch', '-D', branch)
    end

    # Runs checkout command to checkout or create branch
    #
    # accepts options:
    #  :new_branch
    #  :force
    #  :start_point
    #
    # @param [String] branch
    # @param [Hash] opts
    def checkout(branch = nil, opts = {})
      if branch.is_a?(Hash) && opts == {}
        opts = branch
        branch = nil
      end

      arr_opts = []
      arr_opts << '-b' if opts[:new_branch] || opts[:b]
      arr_opts << '--force' if opts[:force] || opts[:f]
      arr_opts << branch if branch
      arr_opts << opts[:start_point] if opts[:start_point] && arr_opts.include?('-b')

      command('checkout', *arr_opts)
    end

    def checkout_file(version, file)
      arr_opts = []
      arr_opts << version
      arr_opts << file
      command('checkout', *arr_opts)
    end

    def merge(branch, message = nil, opts = {})
      arr_opts = []
      arr_opts << '--no-commit' if opts[:no_commit]
      arr_opts << '--no-ff' if opts[:no_ff]
      arr_opts << '-m' << message if message
      arr_opts += Array(branch)
      command('merge', *arr_opts)
    end

    def merge_base(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}

      arg_opts = []

      arg_opts << '--octopus' if opts[:octopus]
      arg_opts << '--independent' if opts[:independent]
      arg_opts << '--fork-point' if opts[:fork_point]
      arg_opts << '--all' if opts[:all]

      arg_opts += args

      command('merge-base', *arg_opts).lines.map(&:strip)
    end

    def unmerged
      unmerged = []
      command_lines('diff', '--cached').each do |line|
        unmerged << ::Regexp.last_match(1) if line =~ /^\* Unmerged path (.*)/
      end
      unmerged
    end

    def conflicts # :yields: file, your, their
      unmerged.each do |file_path|
        Tempfile.create(['YOUR-', File.basename(file_path)]) do |your_file|
          write_staged_content(file_path, 2, your_file).flush

          Tempfile.create(['THEIR-', File.basename(file_path)]) do |their_file|
            write_staged_content(file_path, 3, their_file).flush
            yield(file_path, your_file.path, their_file.path)
          end
        end
      end
    end

    def remote_add(name, url, opts = {})
      arr_opts = ['add']
      arr_opts << '-f' if opts[:with_fetch] || opts[:fetch]
      arr_opts << '-t' << opts[:track] if opts[:track]
      arr_opts << '--'
      arr_opts << name
      arr_opts << url

      command('remote', *arr_opts)
    end

    def remote_set_url(name, url)
      arr_opts = ['set-url']
      arr_opts << name
      arr_opts << url

      command('remote', *arr_opts)
    end

    def remote_remove(name)
      command('remote', 'rm', name)
    end

    def remotes
      command_lines('remote')
    end

    def tags
      command_lines('tag')
    end

    def tag(name, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      target = args.first

      validate_tag_options!(opts)

      cmd_args = build_tag_flags(opts)
      cmd_args.push(name, target).compact!
      cmd_args.push('-m', opts[:m] || opts[:message]) if opts[:m] || opts[:message]

      command('tag', *cmd_args)
    end

    def fetch(remote, opts)
      args = build_fetch_args(opts)

      if remote || opts[:ref]
        args << '--'
        args << remote if remote
        args << opts[:ref] if opts[:ref]
      end

      command('fetch', *args, merge: true)
    end

    def push(remote = nil, branch = nil, opts = nil)
      remote, branch, opts = normalize_push_args(remote, branch, opts)
      raise ArgumentError, 'remote is required if branch is specified' if !remote && branch

      args = build_push_args(remote, branch, opts)

      if opts[:mirror]
        command('push', *args)
      else
        command('push', *args)
        command('push', '--tags', *(args - [branch].compact)) if opts[:tags]
      end
    end

    def pull(remote = nil, branch = nil, opts = {})
      raise ArgumentError, 'You must specify a remote if a branch is specified' if remote.nil? && !branch.nil?

      arr_opts = []
      arr_opts << '--allow-unrelated-histories' if opts[:allow_unrelated_histories]
      arr_opts << remote if remote
      arr_opts << branch if branch
      command('pull', *arr_opts)
    end

    def tag_sha(tag_name)
      head = File.join(@git_dir, 'refs', 'tags', tag_name)
      return File.read(head).chomp if File.exist?(head)

      begin
        command('show-ref', '--tags', '-s', tag_name)
      rescue Git::FailedError => e
        raise unless e.result.status.exitstatus == 1 && e.result.stderr == ''

        ''
      end
    end

    def repack
      command('repack', '-a', '-d')
    end

    def gc
      command('gc', '--prune', '--aggressive', '--auto')
    end

    # reads a tree into the current index file
    def read_tree(treeish, opts = {})
      arr_opts = []
      arr_opts << "--prefix=#{opts[:prefix]}" if opts[:prefix]
      arr_opts += [treeish]
      command('read-tree', *arr_opts)
    end

    def write_tree
      command('write-tree')
    end

    def commit_tree(tree, opts = {})
      opts[:message] ||= "commit tree #{tree}"
      arr_opts = []
      arr_opts << tree
      arr_opts << '-p' << opts[:parent] if opts[:parent]
      Array(opts[:parents]).each { |p| arr_opts << '-p' << p } if opts[:parents]
      arr_opts << '-m' << opts[:message]
      command('commit-tree', *arr_opts)
    end

    def update_ref(ref, commit)
      command('update-ref', ref, commit)
    end

    def checkout_index(opts = {})
      arr_opts = []
      arr_opts << "--prefix=#{opts[:prefix]}" if opts[:prefix]
      arr_opts << '--force' if opts[:force]
      arr_opts << '--all' if opts[:all]
      arr_opts << '--' << opts[:path_limiter] if opts[:path_limiter].is_a? String

      command('checkout-index', *arr_opts)
    end

    def archive(sha, file = nil, opts = {})
      file ||= temp_file_name
      format, gzip = parse_archive_format_options(opts)
      args = build_archive_args(sha, format, opts)

      File.open(file, 'wb') { |f| command('archive', *args, out: f) }
      apply_gzip(file) if gzip

      file
    end

    # returns the current version of git, as an Array of Fixnums.
    def current_command_version
      output = command('version')
      version = output[/\d+(\.\d+)+/]
      version_parts = version.split('.').collect(&:to_i)
      version_parts.fill(0, version_parts.length...3)
    end

    # Returns current_command_version <=> other_version
    #
    # @example
    #   lib.current_command_version #=> [2, 42, 0]
    #
    #   lib.compare_version_to(2, 41, 0) #=> 1
    #   lib.compare_version_to(2, 42, 0) #=> 0
    #   lib.compare_version_to(2, 43, 0) #=> -1
    #
    # @param other_version [Array<Object>] the other version to compare to
    # @return [Integer] -1 if this version is less than other_version, 0 if equal, or 1 if greater than
    #
    def compare_version_to(*other_version)
      current_command_version <=> other_version
    end

    def required_command_version
      [2, 28]
    end

    def meets_required_version?
      (current_command_version <=> required_command_version) >= 0
    end

    def self.warn_if_old_command(lib) # rubocop:disable Naming/PredicateMethod
      Git::Deprecation.warn('Git::Lib#warn_if_old_command is deprecated. Use meets_required_version?.')

      return true if @version_checked

      @version_checked = true
      unless lib.meets_required_version?
        warn "[WARNING] The git gem requires git #{lib.required_command_version.join('.')} or later, " \
             "but only found #{lib.current_command_version.join('.')}. You should probably upgrade."
      end
      true
    end

    COMMAND_ARG_DEFAULTS = {
      out: nil,
      err: nil,
      normalize: true,
      chomp: true,
      merge: false,
      chdir: nil,
      timeout: nil # Don't set to Git.config.timeout here since it is mutable
    }.freeze

    STATIC_GLOBAL_OPTS = %w[
      -c core.quotePath=true
      -c color.ui=false
      -c color.advice=false
      -c color.diff=false
      -c color.grep=false
      -c color.push=false
      -c color.remote=false
      -c color.showBranch=false
      -c color.status=false
      -c color.transport=false
    ].freeze

    private

    def initialize_from_base(base_object)
      @git_dir = base_object.repo.path
      @git_index_file = base_object.index&.path
      @git_work_dir = base_object.dir&.path
    end

    def initialize_from_hash(base_hash)
      @git_dir = base_hash[:repository]
      @git_index_file = base_hash[:index]
      @git_work_dir = base_hash[:working_directory]
    end

    def build_clone_args(repository_url, clone_dir, opts)
      args = build_clone_flag_opts(opts)
      args += build_clone_valued_opts(opts)
      args.push('--', repository_url, clone_dir)
    end

    def build_clone_flag_opts(opts)
      args = []
      args << '--bare' if opts[:bare]
      args << '--recursive' if opts[:recursive]
      args << '--mirror' if opts[:mirror]
      args
    end

    def build_clone_valued_opts(opts)
      args = []
      args.push('--branch', opts[:branch]) if opts[:branch]
      args.push('--depth', opts[:depth].to_i) if opts[:depth]
      args.push('--filter', opts[:filter]) if opts[:filter]

      if (origin_name = opts[:remote] || opts[:origin])
        args.push('--origin', origin_name)
      end

      Array(opts[:config]).each { |c| args.push('--config', c) }
      args
    end

    def return_base_opts_from_clone(clone_dir, opts)
      base_opts = {}
      base_opts[:repository] = clone_dir if opts[:bare] || opts[:mirror]
      base_opts[:working_directory] = clone_dir unless opts[:bare] || opts[:mirror]
      base_opts[:log] = opts[:log] if opts[:log]
      base_opts
    end

    def build_describe_boolean_opts(opts)
      args = []
      args << '--all' if opts[:all]
      args << '--tags' if opts[:tags]
      args << '--contains' if opts[:contains]
      args << '--debug' if opts[:debug]
      args << '--long' if opts[:long]
      args << '--always' if opts[:always]
      args << '--exact-match' if opts[:exact_match] || opts[:'exact-match']
      args
    end

    def build_describe_valued_opts(opts)
      args = []
      args << "--abbrev=#{opts[:abbrev]}" if opts[:abbrev]
      args << "--candidates=#{opts[:candidates]}" if opts[:candidates]
      args << "--match=#{opts[:match]}" if opts[:match]
      args
    end

    def build_describe_dirty_opt(opts)
      return ['--dirty'] if opts[:dirty] == true
      return ["--dirty=#{opts[:dirty]}"] if opts[:dirty].is_a?(String)

      []
    end

    def process_commit_headers(data)
      headers = { 'parent' => [] } # Pre-initialize for multiple parents
      each_cat_file_header(data) do |key, value|
        if key == 'parent'
          headers['parent'] << value
        else
          headers[key] = value
        end
      end
      headers
    end

    def parse_branch_line(line, index, all_lines)
      match_data = match_branch_line(line, index, all_lines)

      return nil if match_data[:not_a_branch] || match_data[:detached_ref]

      format_branch_data(match_data)
    end

    def match_branch_line(line, index, all_lines)
      match_data = line.match(BRANCH_LINE_REGEXP)
      raise Git::UnexpectedResultError, unexpected_branch_line_error(all_lines, line, index) unless match_data

      match_data
    end

    def format_branch_data(match_data)
      [
        match_data[:refname],
        !match_data[:current].nil?,
        !match_data[:worktree].nil?,
        match_data[:symref]
      ]
    end

    def unexpected_branch_line_error(lines, line, index)
      <<~ERROR
        Unexpected line in output from `git branch -a`, line #{index + 1}

        Full output:
          #{lines.join("\n  ")}

        Line #{index + 1}:
          "#{line}"
      ERROR
    end

    def get_branch_state(branch_name)
      command('rev-parse', '--verify', '--quiet', branch_name)
      :active
    rescue Git::FailedError => e
      # An exit status of 1 with empty stderr from `rev-parse --verify`
      # indicates a ref that exists but does not yet point to a commit.
      raise unless e.result.status.exitstatus == 1 && e.result.stderr.empty?

      :unborn
    end

    def build_grep_args(string, opts)
      args = ['-n'] # Always get line numbers
      args << '-i' if opts[:ignore_case]
      args << '-v' if opts[:invert_match]
      args << '-E' if opts[:extended_regexp]
      args.push('-e', string, opts[:object])

      if (limiter = opts[:path_limiter])
        args << '--'
        args.concat(Array(limiter))
      end
      args
    end

    def execute_grep_command(args)
      command_lines('grep', *args)
    rescue Git::FailedError => e
      # `git grep` returns 1 when no lines are selected.
      raise unless e.result.status.exitstatus == 1 && e.result.stderr.empty?

      [] # Return an empty array for "no matches found"
    end

    def parse_grep_output(lines)
      lines.each_with_object(Hash.new { |h, k| h[k] = [] }) do |line, hsh|
        match = line.match(/\A(.*?):(\d+):(.*)/)
        next unless match

        _full, filename, line_num, text = match.to_a
        hsh[filename] << [line_num.to_i, text]
      end
    end

    def build_diff_stats_args(obj1, obj2, opts)
      args = ['--numstat']
      args << obj1
      args << obj2 if obj2.is_a?(String)
      args << '--' << opts[:path_limiter] if opts[:path_limiter].is_a?(String)
      args
    end

    def parse_diff_stats_output(lines)
      file_stats = parse_stat_lines(lines)
      build_final_stats_hash(file_stats)
    end

    def parse_stat_lines(lines)
      lines.map do |line|
        insertions_s, deletions_s, filename = line.split("\t")
        {
          filename: filename,
          insertions: insertions_s.to_i,
          deletions: deletions_s.to_i
        }
      end
    end

    def build_final_stats_hash(file_stats)
      {
        total: build_total_stats(file_stats),
        files: build_files_hash(file_stats)
      }
    end

    def build_total_stats(file_stats)
      insertions = file_stats.sum { |s| s[:insertions] }
      deletions = file_stats.sum { |s| s[:deletions] }
      {
        insertions: insertions,
        deletions: deletions,
        lines: insertions + deletions,
        files: file_stats.size
      }
    end

    def build_files_hash(file_stats)
      file_stats.to_h { |s| [s[:filename], s.slice(:insertions, :deletions)] }
    end

    def parse_ls_remote_output(lines)
      lines.each_with_object(Hash.new { |h, k| h[k] = {} }) do |line, hsh|
        type, name, value = parse_ls_remote_line(line)
        if name
          hsh[type][name] = value
        else # Handles the HEAD entry, which has no name
          hsh[type].update(value)
        end
      end
    end

    def parse_ls_remote_line(line)
      sha, info = line.split("\t", 2)
      ref, type, name = info.split('/', 3)

      type ||= 'head'
      type = 'branches' if type == 'heads'

      value = { ref: ref, sha: sha }

      [type, name, value]
    end

    def build_commit_general_opts(opts)
      args = []
      args << '--amend' << '--no-edit' if opts[:amend]
      args << '--all' if opts[:add_all] || opts[:all]
      args << '--allow-empty' if opts[:allow_empty]
      args << "--author=#{opts[:author]}" if opts[:author]
      args << "--date=#{opts[:date]}" if opts[:date].is_a?(String)
      args << '--no-verify' if opts[:no_verify]
      args << '--allow-empty-message' if opts[:allow_empty_message]
      args
    end

    def build_commit_gpg_opts(opts)
      raise ArgumentError, 'cannot specify :gpg_sign and :no_gpg_sign' if opts[:gpg_sign] && opts[:no_gpg_sign]

      return ['--no-gpg-sign'] if opts[:no_gpg_sign]

      if (key = opts[:gpg_sign])
        return key == true ? ['--gpg-sign'] : ["--gpg-sign=#{key}"]
      end

      []
    end

    def stash_log_lines
      path = File.join(@git_dir, 'logs/refs/stash')
      return [] unless File.exist?(path)

      File.readlines(path, chomp: true)
    end

    def parse_stash_log_line(line, index)
      full_message = line.split("\t", 2).last
      match_data = full_message.match(/^[^:]+:(.*)$/)
      message = match_data ? match_data[1] : full_message

      [index, message.strip]
    end

    # Writes the staged content of a conflicted file to an IO stream
    #
    # @param path [String] the path to the file in the index
    #
    # @param stage [Integer] the stage of the file to show (e.g., 2 for 'ours', 3 for 'theirs')
    #
    # @param out_io [IO] the IO object to write the staged content to
    #
    # @return [IO] the IO object that was written to
    #
    def write_staged_content(path, stage, out_io)
      command('show', ":#{stage}:#{path}", out: out_io)
      out_io
    end

    def validate_tag_options!(opts)
      is_annotated = opts[:a] || opts[:annotate]
      has_message = opts[:m] || opts[:message]

      return unless is_annotated && !has_message

      raise ArgumentError, 'Cannot create an annotated tag without a message.'
    end

    def build_tag_flags(opts)
      flags = []
      flags << '-f' if opts[:force] || opts[:f]
      flags << '-a' if opts[:a] || opts[:annotate]
      flags << '-s' if opts[:s] || opts[:sign]
      flags << '-d' if opts[:d] || opts[:delete]
      flags
    end

    def build_fetch_args(opts)
      args = []
      args << '--all' if opts[:all]
      args << '--tags' if opts[:t] || opts[:tags]
      args << '--prune' if opts[:p] || opts[:prune]
      args << '--prune-tags' if opts[:P] || opts[:'prune-tags']
      args << '--force' if opts[:f] || opts[:force]
      args << '--update-head-ok' if opts[:u] || opts[:'update-head-ok']
      args << '--unshallow' if opts[:unshallow]
      args.push('--depth', opts[:depth]) if opts[:depth]
      args
    end

    def normalize_push_args(remote, branch, opts)
      if branch.is_a?(Hash)
        opts = branch
        branch = nil
      elsif remote.is_a?(Hash)
        opts = remote
        remote = nil
      end

      opts ||= {}
      # Backwards compatibility for `push(remote, branch, true)`
      opts = { tags: opts } if [true, false].include?(opts)
      [remote, branch, opts]
    end

    def build_push_args(remote, branch, opts)
      args = []
      args << '--mirror' if opts[:mirror]
      args << '--delete' if opts[:delete]
      args << '--force' if opts[:force] || opts[:f]
      args << '--all' if opts[:all] && remote

      Array(opts[:push_option]).each { |o| args.push('--push-option', o) } if opts[:push_option]

      args << remote if remote
      args << branch if branch
      args
    end

    def temp_file_name
      tempfile = Tempfile.new('archive')
      file = tempfile.path
      tempfile.close! # Prevents Ruby from deleting the file on garbage collection
      file
    end

    def parse_archive_format_options(opts)
      format = opts[:format] || 'zip'
      gzip = opts[:add_gzip] == true || format == 'tgz'
      format = 'tar' if format == 'tgz'
      [format, gzip]
    end

    def build_archive_args(sha, format, opts)
      args = ["--format=#{format}"]
      %i[prefix remote].each { |name| args << "--#{name}=#{opts[name]}" if opts[name] }
      args << sha
      args << '--' << opts[:path] if opts[:path]
      args
    end

    def apply_gzip(file)
      file_content = File.read(file)
      Zlib::GzipWriter.open(file) { |gz| gz.write(file_content) }
    end

    def command_lines(cmd, *opts, chdir: nil)
      cmd_op = command(cmd, *opts, chdir: chdir)
      op = if cmd_op.encoding.name == 'UTF-8'
             cmd_op
           else
             cmd_op.encode('UTF-8', 'binary', invalid: :replace, undef: :replace)
           end
      op.split("\n")
    end

    def env_overrides
      {
        'GIT_DIR' => @git_dir,
        'GIT_WORK_TREE' => @git_work_dir,
        'GIT_INDEX_FILE' => @git_index_file,
        'GIT_SSH' => Git::Base.config.git_ssh,
        'LC_ALL' => 'en_US.UTF-8'
      }
    end

    def global_opts
      [].tap do |global_opts|
        global_opts << "--git-dir=#{@git_dir}" unless @git_dir.nil?
        global_opts << "--work-tree=#{@git_work_dir}" unless @git_work_dir.nil?
        global_opts.concat(STATIC_GLOBAL_OPTS)
      end
    end

    def command_line
      @command_line ||=
        Git::CommandLine.new(env_overrides, Git::Base.config.binary_path, global_opts, @logger)
    end

    # Runs a git command and returns the output
    #
    # Additional args are passed to the command line. They should exclude the 'git'
    # command itself and global options. Remember to splat the the arguments if given
    # as an array.
    #
    # For example, to run `git log --pretty=oneline`, you would create the array
    # `args = ['log', '--pretty=oneline']` and call `command(*args)`.
    #
    # @param options_hash [Hash] the options to pass to the command
    # @option options_hash [IO, String, #write, nil] :out the destination for captured stdout
    # @option options_hash [IO, String, #write, nil] :err the destination for captured stderr
    # @option options_hash [Boolean] :normalize true to normalize the output encoding to UTF-8
    # @option options_hash [Boolean] :chomp true to remove trailing newlines from the output
    # @option options_hash [Boolean] :merge true to merge stdout and stderr into a single output
    # @option options_hash [String, nil] :chdir the directory to run the command in
    # @option options_hash [Numeric, nil] :timeout the maximum seconds to wait for the command to complete
    #
    #   If timeout is nil, the global timeout from {Git::Config} is used.
    #
    #   If timeout is zero, the timeout will not be enforced.
    #
    #   If the command times out, it is killed via a `SIGKILL` signal and `Git::TimeoutError` is raised.
    #
    #   If the command does not respond to SIGKILL, it will hang this method.
    #
    # @see Git::CommandLine#run
    #
    # @return [String] the command's stdout (or merged stdout and stderr if `merge`
    # is true)
    #
    # @raise [ArgumentError] if an unknown option is passed
    #
    # @raise [Git::FailedError] if the command failed
    #
    # @raise [Git::SignaledError] if the command was signaled
    #
    # @raise [Git::TimeoutError] if the command times out
    #
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    #
    #   The exception's `result` attribute is a {Git::CommandLineResult} which will
    #   contain the result of the command including the exit status, stdout, and
    #   stderr.
    #
    # @api private
    #
    def command(*, **options_hash)
      options_hash = COMMAND_ARG_DEFAULTS.merge(options_hash)
      options_hash[:timeout] ||= Git.config.timeout

      extra_options = options_hash.keys - COMMAND_ARG_DEFAULTS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      result = command_line.run(*, **options_hash)
      result.stdout
    end

    # Takes the diff command line output (as Array) and parse it into a Hash
    #
    # @param [String] diff_command the diff commadn to be used
    # @param [Array] opts the diff options to be used
    # @return [Hash] the diff as Hash
    def diff_as_hash(diff_command, opts = [])
      # update index before diffing to avoid spurious diffs
      command('status')
      command_lines(diff_command, *opts).each_with_object({}) do |line, memo|
        info, file = line.split("\t")
        mode_src, mode_dest, sha_src, sha_dest, type = info.split

        memo[file] = {
          mode_index: mode_dest, mode_repo: mode_src.to_s[1, 7],
          path: file, sha_repo: sha_src, sha_index: sha_dest,
          type: type
        }
      end
    end

    # Returns an array holding the common options for the log commands
    #
    # @param [Hash] opts the given options
    # @return [Array] the set of common options that the log command will use
    def log_common_options(opts)
      if opts[:count] && !opts[:count].is_a?(Integer)
        raise ArgumentError, "The log count option must be an Integer but was #{opts[:count].inspect}"
      end

      ['--no-color'].tap do |args|
        # Switches
        %i[all cherry].each { |name| args << "--#{name}" if opts[name] }
        # Args with values
        %i[since until grep author].each { |name| args << "--#{name}=#{opts[name]}" if opts[name] }
        # Special args
        args << "--max-count=#{opts[:count]}" if opts[:count]
        args << "#{opts[:between][0]}..#{opts[:between][1]}" if opts[:between]
      end
    end

    # Retrurns an array holding path options for the log commands
    #
    # @param [Hash] opts the given options
    # @return [Array] the set of path options that the log command will use
    def log_path_options(opts)
      arr_opts = []

      arr_opts << opts[:object] if opts[:object].is_a? String
      if opts[:path_limiter]
        arr_opts << '--'
        arr_opts += Array(opts[:path_limiter])
      end
      arr_opts
    end
  end
end
