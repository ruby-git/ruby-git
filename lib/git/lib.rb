# frozen_string_literal: true

require_relative 'args_builder'
require_relative 'commands/add'
require_relative 'commands/am'
require_relative 'commands/archive'
require_relative 'commands/apply'
require_relative 'commands/branch/create'
require_relative 'commands/branch/delete'
require_relative 'commands/branch/list'
require_relative 'commands/branch/show_current'
require_relative 'commands/checkout/branch'
require_relative 'commands/checkout/files'
require_relative 'commands/checkout_index'
require_relative 'commands/cat_file/batch'
require_relative 'commands/cat_file/filtered'
require_relative 'commands/cat_file/raw'
require_relative 'commands/clean'
require_relative 'commands/clone'
require_relative 'commands/commit'
require_relative 'commands/commit_tree'
require_relative 'commands/describe'
require_relative 'commands/diff'
require_relative 'commands/diff_files'
require_relative 'commands/diff_index'
require_relative 'commands/fetch'
require_relative 'commands/fsck'
require_relative 'commands/grep'
require_relative 'commands/init'
require_relative 'commands/log'
require_relative 'commands/ls_files'
require_relative 'commands/ls_remote'
require_relative 'commands/ls_tree'
require_relative 'commands/merge/start'
require_relative 'commands/merge_base'
require_relative 'commands/mv'
require_relative 'commands/name_rev'
require_relative 'commands/pull'
require_relative 'commands/push'
require_relative 'commands/read_tree'
require_relative 'commands/reset'
require_relative 'commands/rev_parse'
require_relative 'commands/revert'
require_relative 'commands/remote/add'
require_relative 'commands/remote/get_url'
require_relative 'commands/remote/list'
require_relative 'commands/remote/prune'
require_relative 'commands/remote/remove'
require_relative 'commands/remote/rename'
require_relative 'commands/remote/set_branches'
require_relative 'commands/remote/set_head'
require_relative 'commands/remote/set_url'
require_relative 'commands/remote/set_url_add'
require_relative 'commands/remote/set_url_delete'
require_relative 'commands/remote/show'
require_relative 'commands/remote/update'
require_relative 'commands/rm'
require_relative 'commands/show'
require_relative 'commands/status'
require_relative 'commands/tag/create'
require_relative 'commands/tag/delete'
require_relative 'commands/tag/list'
require_relative 'commands/stash/apply'
require_relative 'commands/stash/clear'
require_relative 'commands/stash/list'
require_relative 'commands/stash/push'
require_relative 'commands/show_ref/exclude_existing'
require_relative 'commands/show_ref/exists'
require_relative 'commands/show_ref/list'
require_relative 'commands/show_ref/verify'
require_relative 'commands/update_ref/update'
require_relative 'commands/write_tree'

require 'git/command_line'
require 'git/errors'
require 'git/parsers/branch'
require 'git/parsers/fsck'
require 'git/parsers/stash'
require 'git/parsers/tag'
require 'git/url'
require 'logger'
require 'pathname'
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
      @git_ssh = :use_global_config

      case base
      when Git::Base
        initialize_from_base(base)
      when Hash
        initialize_from_hash(base)
      end
    end

    # creates or reinitializes the repository in the current directory
    #
    # This is a low-level method that just runs `git init` with the given options.
    # For full repository initialization including directory creation and path
    # resolution, use Git.init instead.
    #
    # @param opts [Hash] command options
    # @option opts [Boolean] :bare Create a bare repository
    # @option opts [String] :initial_branch Use the specified name for the initial branch
    # @option opts [String] :separate_git_dir Path to put the .git directory (`--separate-git-dir`)
    # @option opts [String] :repository Deprecated — use :separate_git_dir instead
    #
    # @return [String] the command output
    #
    def init(opts = {})
      opts = opts.dup
      opts[:separate_git_dir] ||= opts.delete(:repository)
      Git::Commands::Init.new(self).call(**opts).stdout
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
    # @option opts [String, nil] :git_ssh SSH command or binary to use for git over SSH
    #
    # @option opts [Logger] :log Logger instance to use for git operations
    #
    # @option opts [String] :mirror set up a mirror of the source repository
    #
    # @option opts [String] :origin the name of the remote
    #
    # @option opts [String] :chdir run `git clone` from this directory
    #
    #   When given, `directory` (or the repository basename when `directory` is nil)
    #   is resolved relative to `:chdir`, just as if you had `cd`'d into it before
    #   running `git clone`. The returned path is the join of `:chdir` and the
    #   cloned directory path.
    #
    # @option opts [String] :path Deprecated. Use `:chdir` instead.
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
    def clone(repository_url, directory = nil, opts = {})
      opts = opts.dup
      deprecate_clone_options!(opts)
      chdir = opts.delete(:chdir)
      execution_opts = extract_clone_execution_context_opts(opts)
      opts[:chdir] = chdir if chdir
      command_line_result = Git::Commands::Clone.new(self).call(repository_url, directory, **opts)
      result = build_clone_result(command_line_result, execution_opts)
      prefix_clone_result_paths!(result, chdir)
      result
    end

    # Returns the name of the default branch of the given repository
    #
    # @param repository [URI, Pathname, String] The (possibly remote) repository to clone from
    #
    # @return [String] the name of the default branch
    #
    def repository_default_branch(repository)
      output = Git::Commands::LsRemote.new(self).call(repository, 'HEAD', symref: true).stdout

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

      # Translate legacy :"exact-match" (hyphenated) key to :exact_match (underscored)
      opts = opts.dup
      opts[:exact_match] ||= opts.delete(:'exact-match') if opts.key?(:'exact-match')

      commit_ishes = Array(commit_ish).compact
      Git::Commands::Describe.new(self).call(*commit_ishes, **opts).stdout
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
    # @option opts :path_limiter [String, Pathname, Array<String, Pathname>] only include commits that
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
      assert_valid_opts(opts, FULL_LOG_ALLOWED_OPTS)
      validate_log_count_option!(opts)

      call_opts = log_base_call_options(opts, skip: opts[:skip], merges: opts[:merges])
      run_log_command(log_revision_range_args(opts), call_opts)
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
    #
    def rev_parse(revision)
      Git::Commands::RevParse.new(self).call(revision, '--', revs_only: true).stdout
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

      Git::Commands::NameRev.new(self).call(commit_ish).stdout.split[1]
    end

    alias namerev name_rev

    # Returns the raw content of a git object, or streams it into a tempfile
    #
    # Without a block, the full content is buffered in memory and returned as a
    # `String`. With a block, git output is streamed directly to disk without memory
    # buffering — safe for large blobs.
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file
    #
    # @overload cat_file_contents(object)
    #   Returns the object's raw content as a string.
    #
    #   @param object [String] the object name (SHA, ref, `HEAD`, treeish path, etc.)
    #
    #   @return [String] the raw content of the object
    #
    #   @raise [ArgumentError] if `object` starts with a hyphen
    #
    #   @raise [Git::FailedError] if the object does not exist or the command fails
    #
    #   @example Get the contents of a blob
    #     lib.cat_file_contents('HEAD:README.md') # => "This is a README file\n"
    #
    # @overload cat_file_contents(object, &block)
    #   Streams the object's raw content to a temporary file and yields it.
    #
    #   Git output is written directly to a file on disk without being
    #   buffered in memory first, then the file is rewound and yielded to the block.
    #   The return value is whatever the block returns.
    #
    #   @param object [String] the object name (SHA, ref, `HEAD`, treeish path, etc.)
    #
    #   @yield [file] the temporary file containing the streamed content, positioned at the start
    #
    #   @yieldparam file [File] readable `IO` object positioned at the beginning of the content
    #
    #   @yieldreturn [Object] the value to return from this method
    #
    #   @return [Object] the value returned by the block
    #
    #   @raise [ArgumentError] if `object` starts with a hyphen
    #
    #   @raise [Git::FailedError] if the object does not exist or the command fails
    #
    #   @example Read a large blob without buffering it in memory
    #     lib.cat_file_contents('HEAD:large_file.bin') { |f| process(f) }
    #
    def cat_file_contents(object)
      assert_args_are_not_options('object', object)

      return Git::Commands::CatFile::Raw.new(self).call(object, p: true).stdout unless block_given?

      # Stream git output directly to a tempfile to avoid buffering large
      # object content in memory when a block is given.
      Tempfile.create do |file|
        file.binmode
        Git::Commands::CatFile::Raw.new(self).call(object, p: true, out: file)
        file.rewind
        yield file
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

      cat_file_object_meta(object)[:type]
    end

    alias object_type cat_file_type

    # Get the size for the given object
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file
    #
    # @param object [String] the object to get the size of
    #
    # @return [Integer] the object size in bytes
    #
    # @raise [ArgumentError] if object is a string starting with a hyphen
    #
    def cat_file_size(object)
      assert_args_are_not_options('object', object)

      cat_file_object_meta(object)[:size]
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

      cdata = Git::Commands::CatFile::Raw.new(self).call('commit', object).stdout.split("\n")
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

    # Yields parsed header key/value pairs from `git cat-file` output lines
    #
    # Consumes header lines from the front of `data` until a non-header line is
    # encountered. Continuation lines that begin with a space are folded into the
    # previous header value using newline separators.
    #
    # @param data [Array<String>] mutable output lines from a cat-file response
    #
    # @yield [key, value] each parsed header pair
    #
    # @yieldparam key [String] header field name
    #
    # @yieldparam value [String] unfolded header value text
    #
    # @yieldreturn [void]
    #
    # @return [void]
    #
    # @raise [NoMethodError] if `data` contains non-string entries
    #
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

      tdata = Git::Commands::CatFile::Raw.new(self).call('tag', object).stdout.split("\n")
      process_tag_data(tdata, object)
    end

    alias tag_data cat_file_tag

    def cat_file_object_meta(object)
      stdout = Git::Commands::CatFile::Batch.new(self).call(object, batch_check: true).stdout
      parse_cat_file_meta(stdout, object)
    end

    def parse_cat_file_meta(output, object)
      line = output.to_s.lines.first.to_s.chomp

      request_object_to_raise_error!(object) if line == "#{object} missing"

      match = /\A\S+ (?<type>\S+) (?<size>\d+)\z/.match(line)
      raise Git::UnexpectedResultError, "unexpected git cat-file metadata output: #{line.inspect}" if match.nil?

      {
        type: match[:type],
        size: match[:size].to_i
      }
    end

    # Re-request the missing object via non-batch cat-file so git produces a
    # real non-zero exit and a FailedError with an accurate stderr message.
    def request_object_to_raise_error!(object)
      Git::Commands::CatFile::Raw.new(self).call(object, p: true)
      raise Git::UnexpectedResultError,
            "expected git cat-file to raise Git::FailedError for missing object #{object.inspect}"
    end

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

    # Allowed option keys for {#ls_tree}
    LS_TREE_ALLOWED_OPTS = %i[recursive path].freeze

    def ls_tree(sha, opts = {})
      assert_valid_opts(opts, LS_TREE_ALLOWED_OPTS)
      r_value = opts[:recursive]
      paths = Array(opts[:path]).compact
      safe_options = {}
      safe_options[:r] = r_value unless r_value.nil?
      result = Git::Commands::LsTree.new(self).call(sha, *paths, **safe_options)
      parse_ls_tree_output(result.stdout)
    end

    def parse_ls_tree_output(output)
      data = { 'blob' => {}, 'tree' => {}, 'commit' => {} }
      output.split("\n").each do |line|
        (info, filenm) = split_status_line(line)
        (mode, type, entry_sha) = info.split
        data[type][filenm] = { mode: mode, sha: entry_sha }
      end
      data
    end
    private :parse_ls_tree_output

    # @return [String] the command output
    #
    def mv(source, destination, options = {})
      Git::Commands::Mv.new(self).call(*Array(source), destination, verbose: true, **options).stdout
    end

    def full_tree(sha)
      Git::Commands::LsTree.new(self).call(sha, r: true).stdout.split("\n")
    end

    def tree_depth(sha)
      full_tree(sha).size
    end

    def change_head_branch(branch_name)
      command_capturing('symbolic-ref', 'HEAD', "refs/heads/#{branch_name}")
    end

    def branches_all
      result = Git::Commands::Branch::List.new(self).call(all: true, format: Git::Parsers::Branch::FORMAT_STRING)
      Git::Parsers::Branch.parse_list(result.stdout)
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
      command_capturing('worktree', 'list', '--porcelain').stdout.split("\n").each do |w|
        s = w.split
        directory = s[1] if s[0] == 'worktree'
        arr << [directory, s[1]] if s[0] == 'HEAD'
      end
      arr
    end

    # Environment override to exclude GIT_INDEX_FILE for worktree commands
    # Git worktrees manage their own index files and setting GIT_INDEX_FILE
    # causes corruption of both the main worktree and new worktree indexes.
    WORKTREE_ENV = { 'GIT_INDEX_FILE' => nil }.freeze

    def worktree_add(dir, commitish = nil)
      return command_capturing('worktree', 'add', dir, commitish, env: WORKTREE_ENV).stdout unless commitish.nil?

      command_capturing('worktree', 'add', dir, env: WORKTREE_ENV).stdout
    end

    def worktree_remove(dir)
      command_capturing('worktree', 'remove', dir, env: WORKTREE_ENV).stdout
    end

    def worktree_prune
      command_capturing('worktree', 'prune', env: WORKTREE_ENV).stdout
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
      branch_name = Git::Commands::Branch::ShowCurrent.new(self).call.stdout
      return HeadState.new(:detached, 'HEAD') if branch_name.empty?

      state = get_branch_state(branch_name)
      HeadState.new(state, branch_name)
    end

    def branch_current
      result = Git::Commands::Branch::ShowCurrent.new(self).call
      name = result.stdout.strip
      name.empty? ? 'HEAD' : name
    end

    def branch_contains(commit, branch_name = '')
      branch_name = branch_name.to_s
      pattern = branch_name.empty? ? nil : branch_name
      Git::Commands::Branch::List.new(self).call(*[pattern].compact, contains: commit, format: Git::Parsers::Branch::FORMAT_STRING).stdout
    end

    GREP_ALLOWED_OPTS = %i[ignore_case i invert_match v extended_regexp E object path_limiter].freeze

    def grep(pattern, opts = {})
      assert_valid_opts(opts, GREP_ALLOWED_OPTS)

      opts = normalize_grep_opts(opts)
      object = opts.delete(:object) || 'HEAD'
      result = Git::Commands::Grep.new(self).call(object, pattern:, **opts, no_color: true, line_number: true)
      exitstatus = result.status.exitstatus

      # Exit status 1 with empty stderr means no lines matched (not an error)
      return {} if exitstatus == 1 && result.stderr.empty?

      # Exit status 1 with non-empty stderr is a real error (e.g. bad object reference)
      raise Git::FailedError, result if exitstatus == 1

      parse_grep_output(result.stdout.split("\n"))
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

    # Normalizes path specifications for Git commands
    #
    # Converts a single path or array of paths into a consistent array format
    # suitable for appending to Git command arguments after '--'. Empty strings
    # are filtered out after conversion.
    #
    # @param pathspecs [String, Pathname, Array<String, Pathname>, nil] path(s) to normalize
    # @param arg_name [String] name of the argument for error messages
    # @return [Array<String>, nil] normalized array of path strings, or nil if empty/nil input
    # @raise [ArgumentError] if any path is not a String or Pathname
    #
    def normalize_pathspecs(pathspecs, arg_name)
      return nil unless pathspecs

      normalized = Array(pathspecs)
      validate_pathspec_types(normalized, arg_name)

      normalized = normalized.map(&:to_s).reject(&:empty?)
      return nil if normalized.empty?

      normalized
    end

    # Validates that all pathspecs are String or Pathname objects
    #
    # @param pathspecs [Array] the pathspecs to validate
    # @param arg_name [String] name of the argument for error messages
    # @raise [ArgumentError] if any path is not a String or Pathname
    #
    def validate_pathspec_types(pathspecs, arg_name)
      return if pathspecs.all? { |path| path.is_a?(String) || path.is_a?(Pathname) }

      raise ArgumentError, "Invalid #{arg_name}: must be a String, Pathname, or Array of Strings/Pathnames"
    end

    # Allowed option keys for {#full_log_commits}
    FULL_LOG_ALLOWED_OPTS = %i[count all cherry since until grep author between object path_limiter skip merges].freeze

    # Allowed option keys for {#diff_full}
    DIFF_FULL_ALLOWED_OPTS = %i[path_limiter].freeze

    # Allowed option keys for {#diff_stats}
    DIFF_STATS_ALLOWED_OPTS = %i[path_limiter].freeze

    # Allowed option keys for {#diff_path_status}
    DIFF_PATH_STATUS_ALLOWED_OPTS = %i[path_limiter path].freeze

    # Handle deprecated :path option in favor of :path_limiter
    #
    # @param opts [Hash] options hash that may contain :path or :path_limiter
    #
    # @return [String, Pathname, Array<String, Pathname>, nil] the resolved path limiter
    #
    def handle_deprecated_path_option(opts)
      if opts.key?(:path_limiter)
        opts[:path_limiter]
      elsif opts.key?(:path)
        Git::Deprecation.warn(
          'Git::Lib#diff_path_status :path option is deprecated. Use :path_limiter instead.'
        )
        opts[:path]
      end
    end

    # Validate that opts contains only allowed keys
    #
    # @param opts [Hash] options hash to validate
    #
    # @param allowed [Array<Symbol>] allowed option keys
    #
    # @raise [ArgumentError] if unknown keys are present
    #
    def assert_valid_opts(opts, allowed)
      unknown = opts.keys - allowed
      raise ArgumentError, "Unknown options: #{unknown.join(', ')}" if unknown.any?
    end

    # Show full diff patch output between commits or the working tree
    #
    # Delegates to {Git::Commands::Diff}.
    #
    # @param obj1 [String] first commit reference (default: 'HEAD')
    #
    # @param obj2 [String, nil] second commit reference (default: nil)
    #
    # @param opts [Hash] options
    #
    # @option opts [String, Pathname, Array<String, Pathname>] :path_limiter (nil)
    #   pathspecs to limit the diff
    #
    # @return [String] the unified diff patch output
    #
    # @raise [Git::FailedError] if git returns exit code >= 2
    #
    # @see Git::Commands::Diff
    #
    def diff_full(obj1 = 'HEAD', obj2 = nil, opts = {})
      assert_valid_opts(opts, DIFF_FULL_ALLOWED_OPTS)
      pathspecs = normalize_pathspecs(opts[:path_limiter], 'path limiter')
      result = Git::Commands::Diff.new(self).call(
        *[obj1, obj2].compact,
        patch: true, numstat: true, shortstat: true,
        src_prefix: 'a/', dst_prefix: 'b/',
        pathspecs: pathspecs
      )
      extract_patch_text(result.stdout)
    end

    # Show numstat diff output between commits or the working tree
    #
    # Delegates to {Git::Commands::Diff}.
    #
    # @param obj1 [String] first commit reference (default: 'HEAD')
    #
    # @param obj2 [String, nil] second commit reference (default: nil)
    #
    # @param opts [Hash] options
    #
    # @option opts [String, Pathname, Array<String, Pathname>] :path_limiter (nil)
    #   pathspecs to limit the diff
    #
    # @return [Hash] diff statistics with the shape:
    #   `{ total: { insertions:, deletions:, lines:, files: }, files: { ... } }`
    #
    # @raise [Git::FailedError] if git returns exit code >= 2
    #
    # @see Git::Commands::Diff
    #
    def diff_stats(obj1 = 'HEAD', obj2 = nil, opts = {})
      assert_valid_opts(opts, DIFF_STATS_ALLOWED_OPTS)
      pathspecs = normalize_pathspecs(opts[:path_limiter], 'path limiter')
      result = Git::Commands::Diff.new(self).call(
        *[obj1, obj2].compact,
        numstat: true, shortstat: true,
        src_prefix: 'a/', dst_prefix: 'b/',
        pathspecs: pathspecs
      )
      output_lines = extract_numstat_lines(result.stdout)
      parse_diff_stats_output(output_lines)
    end

    # Show path status (name-status) for diff between commits or the working tree
    #
    # Delegates to {Git::Commands::Diff} and extracts status letters and
    # paths from the raw output lines.
    #
    # @param reference1 [String, nil] first commit reference (default: nil)
    #
    # @param reference2 [String, nil] second commit reference (default: nil)
    #
    # @param opts [Hash] options
    #
    # @option opts [String, Pathname, Array<String, Pathname>] :path_limiter (nil)
    #   pathspecs to limit the diff
    #
    # @option opts [String, Pathname, Array<String, Pathname>] :path (nil)
    #   deprecated; use :path_limiter instead
    #
    # @return [Hash] mapping of file paths to status letters
    #   (e.g. `{ "lib/foo.rb" => "M", "README.md" => "A" }`)
    #
    # @raise [Git::FailedError] if git returns exit code >= 2
    #
    # @see Git::Commands::Diff
    #
    def diff_path_status(reference1 = nil, reference2 = nil, opts = {})
      assert_valid_opts(opts, DIFF_PATH_STATUS_ALLOWED_OPTS)

      path_limiter = handle_deprecated_path_option(opts)
      pathspecs = normalize_pathspecs(path_limiter, 'path limiter')
      result = Git::Commands::Diff.new(self).call(
        *[reference1, reference2].compact,
        raw: true, numstat: true, shortstat: true,
        src_prefix: 'a/', dst_prefix: 'b/',
        pathspecs: pathspecs
      )
      extract_name_status_from_raw(result.stdout)
    end

    # compares the index and the working directory
    def diff_files
      Git::Commands::Status.new(self).call
      parse_raw_diff_output(Git::Commands::DiffFiles.new(self).call.stdout)
    end

    # compares the index and the repository
    def diff_index(treeish)
      Git::Commands::Status.new(self).call
      parse_raw_diff_output(Git::Commands::DiffIndex.new(self).call(treeish).stdout)
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
        Git::Commands::LsFiles.new(self).call(location, stage: true).stdout.split("\n").each do |line|
          (info, file) = split_status_line(line)
          (mode, sha, stage) = info.split
          files[file] = {
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
      repository = location || '.'
      output_lines = Git::Commands::LsRemote.new(self).call(repository, **opts).stdout.split("\n")
      parse_ls_remote_output(output_lines)
    end

    def ignored_files
      Git::Commands::LsFiles.new(self).call(
        others: true, ignored: true, exclude_standard: true
      ).stdout.split("\n").map { |f| unescape_quoted_path(f) }
    end

    def untracked_files
      Git::Commands::LsFiles.new(self).call(
        others: true, exclude_standard: true, chdir: @git_work_dir
      ).stdout.split("\n").map { |f| unescape_quoted_path(f) }
    end

    def config_remote(name)
      hsh = {}
      config_list.each do |key, value|
        hsh[key.gsub("remote.#{name}.", '')] = value if /remote.#{name}/.match(key)
      end
      hsh
    end

    def config_get(name)
      command_capturing('config', '--get', name, chdir: @git_dir).stdout
    end

    def global_config_get(name)
      command_capturing('config', '--global', '--get', name).stdout
    end

    def config_list
      parse_config_list command_capturing('config', '--list', chdir: @git_dir).stdout.split("\n")
    end

    def global_config_list
      parse_config_list command_capturing('config', '--global', '--list').stdout.split("\n")
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
      parse_config_list command_capturing('config', '--list', '--file', file).stdout.split("\n")
    end

    # Shows objects
    #
    # @param [String|NilClass] objectish the target object reference (nil == HEAD)
    # @param [String|NilClass] path the path of the file to be shown
    # @return [String] the object information
    def show(objectish = nil, path = nil)
      object = path ? "#{objectish}:#{path}" : objectish
      Git::Commands::Show.new(self).call(*[object].compact).stdout
    end

    ## WRITE COMMANDS ##

    CONFIG_SET_OPTION_MAP = [
      { keys: [:file], flag: '--file', type: :valued_space }
    ].freeze

    def config_set(name, value, options = {})
      ArgsBuilder.validate!(options, CONFIG_SET_OPTION_MAP)
      flags = build_args(options, CONFIG_SET_OPTION_MAP)
      command_capturing('config', *flags, name, value)
    end

    def global_config_set(name, value)
      command_capturing('config', '--global', name, value)
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
    # @return [String] the command output (typically empty on success)
    #
    def add(paths = '.', options = {})
      Git::Commands::Add.new(self).call(*Array(paths), **options).stdout
    end

    # Remove files from the working tree and from the index
    #
    # @param path [String, Array<String>] files or directories to remove
    # @param opts [Hash] command options
    #
    # @option opts [Boolean] :force Force removal, bypassing the up-to-date check. Alias: :f
    # @option opts [Boolean] :recursive Remove directories and their contents recursively
    # @option opts [Boolean] :cached Only remove from the index, keeping working tree files
    #
    # @return [String] the command output
    #
    def rm(path = '.', opts = {})
      Git::Commands::Rm.new(self).call(*Array(path), **opts).stdout
    end

    # Returns true if the repository is empty (meaning it has no commits)
    #
    # @return [Boolean]
    #
    def empty?
      Git::Commands::RevParse.new(self).call('HEAD', verify: true)
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
    #
    def commit(message, opts = {})
      opts = opts.merge(message: message) if message

      # TODO: deprecate :no_gpg_sign in favor of :gpg_sign => false
      # This adapter was added to maintain backward compatibility
      if opts[:no_gpg_sign]
        Git::Deprecation.warn(':no_gpg_sign option is deprecated. Use :gpg_sign => false instead.')

        raise ArgumentError, 'cannot specify :gpg_sign and :no_gpg_sign' if opts.key?(:gpg_sign)

        opts.delete(:no_gpg_sign)
        opts[:gpg_sign] = false
      end

      deprecate_commit_add_all_option!(opts)

      Git::Commands::Commit.new(self).call(edit: false, **opts).stdout
    end

    # @return [String] the command output
    #
    def reset(commit = nil, opts = {})
      Git::Commands::Reset.new(self).call(commit, **opts).stdout
    end

    # @return [String] the command output
    #
    def clean(opts = {})
      if opts.key?(:ff)
        Git::Deprecation.warn(':ff option is deprecated. Use :force_force instead.')
        opts = opts.dup
        opts[:force_force] = opts.delete(:ff)
      end
      Git::Commands::Clean.new(self).call(**opts).stdout
    end

    REVERT_ALLOWED_OPTS = %i[no_edit].freeze

    def revert(commitish, opts = {})
      assert_valid_opts(opts, REVERT_ALLOWED_OPTS)
      opts = { no_edit: true }.merge(opts)
      opts[:edit] = false if opts.delete(:no_edit)
      Git::Commands::Revert::Start.new(self).call(commitish, **opts).stdout
    end

    def apply(patch_file)
      Git::Commands::Apply.new(self).call(*[patch_file].compact, chdir: @git_work_dir).stdout
    end

    def apply_mail(patch_file)
      Git::Commands::Am::Apply.new(self).call(*[patch_file].compact, chdir: @git_work_dir).stdout
    end

    # Returns all stash entries as an array of index and message pairs
    #
    # List all stash entries in the repository ordered from oldest to newest
    #
    # The index is a sequential number starting from 0 for the oldest stash, and the
    # message is the description of the stash entry.
    #
    # @example List all stashes (oldest first)
    #   lib.stashes_all # => [[0, "Fix bug"], [1, "Add feature"]]
    #
    # @return [Array<Array(Integer, String)>] array of [index, message] pairs where
    #   index is the sequential position (0 is oldest) and message is the stash description
    #
    # @see https://git-scm.com/docs/git-stash git-stash documentation
    #
    def stashes_all
      result = Git::Commands::Stash::List.new(self).call
      stashes = Git::Parsers::Stash.parse_list(result.stdout)
      stashes.reverse.each_with_index.map { |info, i| stash_info_to_legacy(info, i) }
    end

    # Save the current working directory and index state to a new stash
    #
    # This method preserves v4.0.0 backward compatibility by returning a truthy/falsy
    # value indicating whether a stash was created.
    #
    # @param message [String] the stash message
    #
    # @return [Boolean] true if changes were stashed, false if there were no local changes to save
    #
    # @example Save current changes
    #   lib.stash_save('WIP: feature work')
    #
    # @see https://git-scm.com/docs/git-stash git-stash documentation
    #
    def stash_save(message) # rubocop:disable Naming/PredicateMethod
      result = Git::Commands::Stash::Push.new(self).call(message: message)
      !result.stdout.include?('No local changes to save')
    end

    # Apply a stash to the working directory
    #
    # This method preserves v4.0.0 backward compatibility by returning the command output.
    #
    # @param id [String, Integer, nil] the stash identifier (e.g., 'stash@\\{0}', 0) or nil for latest
    #
    # @return [String] the output from the git stash apply command
    #
    # @example Apply the latest stash
    #   lib.stash_apply
    #
    # @example Apply a specific stash
    #   lib.stash_apply('stash@{1}')
    #
    # @see https://git-scm.com/docs/git-stash git-stash documentation
    #
    def stash_apply(id = nil)
      result = Git::Commands::Stash::Apply.new(self).call(id)
      result.stdout
    end

    # Remove all stash entries
    #
    # This method preserves v4.0.0 backward compatibility by returning the command output.
    #
    # @return [String] the output from the git stash clear command
    #
    # @example Clear all stashes
    #   lib.stash_clear
    #
    # @see https://git-scm.com/docs/git-stash git-stash documentation
    #
    def stash_clear
      result = Git::Commands::Stash::Clear.new(self).call
      result.stdout
    end

    # List all stash entries in standard git stash list format
    #
    # This method preserves v4.0.0 backward compatibility by returning a formatted
    # string matching the output of `git stash list`.
    #
    # @return [String] newline-separated list of stash entries in the format
    #   "stash@\\{n}: <message>", or an empty string if no stashes exist
    #
    # @example List all stashes
    #   lib.stash_list # => "stash@\\{0}: On main: WIP\nstash@\\{1}: On feature: test"
    #
    # @see https://git-scm.com/docs/git-stash git-stash documentation
    #
    def stash_list
      result = Git::Commands::Stash::List.new(self).call
      stashes = Git::Parsers::Stash.parse_list(result.stdout)
      stashes.map { |info| "#{info.name}: #{info.message}" }.join("\n")
    end

    # Create a new branch
    #
    # @param branch [String] the name of the branch to create
    # @param start_point [String, nil] the commit, branch, or tag to start the new branch from
    # @param options [Hash] command options (see {Git::Commands::Branch::Create#call})
    #
    # @return [nil]
    #
    def branch_new(branch, start_point = nil, options = {})
      Git::Commands::Branch::Create.new(self).call(branch, start_point, **options)
      nil
    end

    # Delete one or more branches
    #
    # @param branches [Array<String>] the name(s) of the branch(es) to delete
    # @param options [Hash] command options (see {Git::Commands::Branch::Delete#call})
    # @option options [Boolean] :force allow deleting unmerged branches (default: true for backward compatibility)
    # @option options [Boolean] :remotes delete remote-tracking branches
    #
    # @return [String] newline-separated list of "Deleted branch <name> (was <sha>)." messages
    #
    # @raise [Git::Error] if any branch fails to delete
    #
    def branch_delete(*branches, **options)
      options = { force: true }.merge(options)
      result = Git::Commands::Branch::Delete.new(self).call(*branches, **options)

      raise Git::Error, result.stderr.strip unless result.status.success?

      result.stdout.strip
    end

    # Runs checkout command to checkout or create branch
    #
    # accepts options:
    #  :new_branch / :b - create a new branch with the given name (true = legacy, string = new)
    #  :force / :f - proceed even with uncommitted changes
    #  :start_point - start the new branch at this commit (used with :new_branch in legacy mode)
    #
    # @param [String] branch the branch to checkout, or nil
    # @param [Hash] opts options for the checkout command
    # @return [String] the command output
    #
    def checkout(branch = nil, opts = {})
      if branch.is_a?(Hash) && opts.empty?
        opts = branch
        branch = nil
      end

      target, translated_opts = translate_checkout_opts(branch, opts)
      Git::Commands::Checkout::Branch.new(self).call(target, **translated_opts).stdout
    end

    # Translates legacy checkout options to the new command interface.
    # Legacy: checkout('branch', new_branch: true, start_point: 'main')
    # New: checkout('main', b: 'branch')
    def translate_checkout_opts(branch, opts)
      if opts[:new_branch] == true || opts[:b] == true
        [opts[:start_point], opts.except(:new_branch, :b, :start_point).merge(b: branch)]
      elsif opts[:new_branch].is_a?(String)
        [branch, opts.except(:new_branch).merge(b: opts[:new_branch])]
      else
        [branch, opts]
      end
    end
    private :translate_checkout_opts

    # Checkout a specific version of a file
    #
    # @param version [String] the tree-ish (commit, branch, tag) to restore from
    # @param file [String] the file path to restore
    # @return [String] the command output
    #
    def checkout_file(version, file)
      Git::Commands::Checkout::Files.new(self).call(version, pathspec: [file]).stdout
    end

    # Merge one or more branches into the current branch
    #
    # @param branch [String, Array<String>] branch name(s) to merge
    # @param message [String, nil] commit message for merge commit
    # @param opts [Hash] merge options
    #
    # @option opts [Boolean] :no_commit (nil) stop before creating merge commit
    #   (deprecated: use commit: false instead)
    # @option opts [Boolean] :no_ff (nil) create merge commit even for fast-forward
    #   (deprecated: use ff: false instead)
    # @option opts [String] :m (nil) commit message (deprecated: use message: option)
    # @option opts [Boolean] :commit (nil) true for --commit, false for --no-commit
    # @option opts [Boolean] :ff (nil) true for --ff, false for --no-ff
    # @option opts [Boolean] :ff_only (nil) only merge if fast-forward possible
    # @option opts [Boolean] :squash (nil) squash commits into single commit
    # @option opts [String] :message (nil) commit message
    # @option opts [String] :strategy (nil) merge strategy (e.g., 'ort', 'ours')
    # @option opts [String, Array<String>] :strategy_option (nil) strategy-specific options
    # @option opts [Boolean] :allow_unrelated_histories (nil) allow merging unrelated histories
    #
    # @return [String] the command output
    #
    def merge(branch, message = nil, opts = {})
      # Handle legacy positional message argument
      opts = opts.merge(message: message) if message

      # Map legacy option names to new interface
      opts = translate_merge_options(opts)

      Git::Commands::Merge::Start.new(self).call(*Array(branch), edit: false, **opts).stdout
    end

    # Find common ancestor commit(s) for merge
    #
    # @overload merge_base(*commits, options = {})
    #
    #   @param commits [Array<String>] commits to find common ancestor(s) of
    #
    #   @param options [Hash] merge-base options
    #
    #   @option options [Boolean] :octopus (nil) compute best ancestor for n-way merge
    #   @option options [Boolean] :independent (nil) list commits not reachable from others
    #   @option options [Boolean] :fork_point (nil) find fork point
    #   @option options [Boolean] :all (nil) output all merge bases
    #
    # @return [Array<String>] array of commit SHAs
    #
    def merge_base(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      result = Git::Commands::MergeBase.new(self).call(*args, **opts)
      result.stdout.lines.map(&:strip).reject(&:empty?)
    end

    # List paths that remain unmerged after a failed or partial merge
    #
    # Delegates to {Git::Commands::Diff}.
    #
    # @return [Array<String>] paths of files with unresolved merge conflicts
    #
    # @raise [Git::FailedError] if git returns exit code >= 2
    #
    # @see Git::Commands::Diff
    #
    def unmerged
      result = Git::Commands::Diff.new(self).call(cached: true)
      result.stdout.split("\n").filter_map do |line|
        ::Regexp.last_match(1) if line =~ /^\* Unmerged path (.*)/
      end
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
      translated_opts = opts.dup
      translated_opts[:fetch] = translated_opts.delete(:with_fetch) if translated_opts.key?(:with_fetch)

      Git::Commands::Remote::Add.new(self).call(name, url, **translated_opts)
    end

    def remote_set_branches(name, branches, opts = {})
      Git::Commands::Remote::SetBranches.new(self).call(name, *Array(branches).flatten, **opts)
    end

    def remote_set_url(name, url, opts = {})
      Git::Commands::Remote::SetUrl.new(self).call(name, url, **opts)
    end

    def remote_remove(name)
      Git::Commands::Remote::Remove.new(self).call(name)
    end

    def remotes
      Git::Commands::Remote::List.new(self).call.stdout.split("\n")
    end

    # List all tags in the repository
    #
    # @see https://git-scm.com/docs/git-tag git-tag
    #
    # @return [Array<String>] tag names
    #
    def tags
      result = Git::Commands::Tag::List.new(self).call(format: Git::Parsers::Tag::FORMAT_STRING)
      Git::Parsers::Tag.parse_list(result.stdout).map(&:name)
    end

    # Create or delete a tag
    #
    # When the `:d` or `:delete` option is set, deletes the named tag.
    # Otherwise, creates a new tag pointing at HEAD or the specified target.
    #
    # @see https://git-scm.com/docs/git-tag git-tag
    #
    # @overload tag(name, target, opts = {})
    #
    #   Create a tag on the specified target
    #
    #   @param name [String] the tag name to create
    #
    #   @param target [String] the commit or object to tag
    #
    #   @param opts [Hash] options for creating the tag
    #
    #   @option opts [Boolean] :annotate (nil) create an unsigned, annotated tag object.
    #     Requires `:message` or `:file`.
    #
    #     Alias: `:a`
    #
    #   @option opts [Boolean] :sign (nil) create a GPG-signed tag. Requires `:message` or `:file`.
    #
    #     Alias: `:s`
    #
    #   @option opts [Boolean] :force (nil) replace an existing tag with the given name.
    #
    #     Alias: `:f`
    #
    #   @option opts [String] :message (nil) use the given string as the tag message.
    #     Implies annotated tag if none of `:annotate`, `:sign`, or `:local_user` is given.
    #
    #     Alias: `:m`
    #
    # @overload tag(name, opts = {})
    #
    #   Create a lightweight tag on HEAD
    #
    #   @param name [String] the tag name to create
    #
    #   @param opts [Hash] options for creating the tag
    #
    #   @option opts [Boolean] :annotate (nil) create an unsigned, annotated tag object.
    #     Requires `:message` or `:file`.
    #
    #     Alias: `:a`
    #
    #   @option opts [Boolean] :sign (nil) create a GPG-signed tag. Requires `:message` or `:file`.
    #
    #     Alias: `:s`
    #
    #   @option opts [Boolean] :force (nil) replace an existing tag with the given name.
    #
    #     Alias: `:f`
    #
    #   @option opts [String] :message (nil) use the given string as the tag message.
    #     Implies annotated tag if none of `:annotate`, `:sign`, or `:local_user` is given.
    #
    #     Alias: `:m`
    #
    # @overload tag(name, opts = {})
    #
    #   Delete the named tag
    #
    #   @param name [String] the tag name to delete
    #
    #   @param opts [Hash] options
    #
    #   @option opts [Boolean] :delete (nil) delete the named tag.
    #
    #     Alias: `:d`
    #
    # @return [String] command output
    #
    # @raise [ArgumentError] if creating an annotated or signed tag without a message
    #
    # @raise [Git::FailedError] if the tag already exists (without `:force`) or if
    #   the tag to delete does not exist
    #
    def tag(name, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      target = args.first

      if opts[:d] || opts[:delete]
        delete_tag(name)
      else
        validate_tag_options!(opts)
        create_tag(name, target, opts)
      end
    end

    FETCH_KEY_NORMALIZATIONS = { 'update-head-ok': :update_head_ok, 'prune-tags': :prune_tags }.freeze

    def fetch(remote, opts)
      opts = opts.transform_keys do |k|
        sym = k.is_a?(Symbol) ? k : k.to_sym
        FETCH_KEY_NORMALIZATIONS.fetch(sym, sym)
      end
      refspecs = Array(opts.delete(:ref)).compact
      positionals = [*([remote] if remote), *refspecs]
      Git::Commands::Fetch.new(self).call(*positionals, **opts, merge: true).stdout
    end

    PUSH_ALLOWED_OPTS = %i[mirror delete force f push_option all tags].freeze

    # Push refs to a remote repository
    #
    # @overload push(options = {})
    #   Push using the current branch's default remote and push configuration
    #
    #   @param options [Hash] push options
    #
    #   @option options [Boolean] :all (nil) Push all branches
    #
    #   @option options [Boolean] :mirror (nil) Push all refs
    #
    #   @option options [Boolean] :tags (nil) Push all tags
    #
    #   @option options [Boolean] :force (nil) Force updates
    #
    #   @option options [Boolean] :delete (nil) Delete the named remote ref
    #
    #   @option options [String, Array<String>] :push_option (nil) Server-side push option values
    #
    #   @return [String] the stdout from the final `git push` invocation
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @overload push(remote, options = {})
    #   Push to the given remote using the current branch's default push configuration
    #
    #   @param remote [String] the remote name or URL to push to
    #
    #   @param options [Hash] push options
    #
    #   @option options [Boolean] :all (nil) Push all branches
    #
    #   @option options [Boolean] :mirror (nil) Push all refs
    #
    #   @option options [Boolean] :tags (nil) Push all tags
    #
    #   @option options [Boolean] :force (nil) Force updates
    #
    #   @option options [Boolean] :delete (nil) Delete the named remote ref
    #
    #   @option options [String, Array<String>] :push_option (nil) Server-side push option values
    #
    #   @return [String] the stdout from the final `git push` invocation
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @overload push(remote, branch, options = {})
    #   Push a branch or refspec to the given remote
    #
    #   @param remote [String] the remote name or URL to push to
    #
    #   @param branch [String] the branch name or refspec to push
    #
    #   @param options [Hash] push options
    #
    #   @option options [Boolean] :all (nil) Push all branches
    #
    #   @option options [Boolean] :mirror (nil) Push all refs
    #
    #   @option options [Boolean] :tags (nil) Push all tags
    #
    #   @option options [Boolean] :force (nil) Force updates
    #
    #   @option options [Boolean] :delete (nil) Delete the named remote ref
    #
    #   @option options [String, Array<String>] :push_option (nil) Server-side push option values
    #
    #   @return [String] the stdout from the final `git push` invocation
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    #   @raise [ArgumentError] if `remote` is nil
    #
    # @overload push(remote, branch, tags)
    #   Backward-compatible shorthand for `push(remote, branch, tags: tags)`
    #
    #   @param remote [String] the remote name or URL to push to
    #
    #   @param branch [String] the branch name or refspec to push
    #
    #   @param tags [Boolean] whether to push all tags
    #
    #   @return [String] the stdout from the final `git push` invocation
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    #   @raise [ArgumentError] if `remote` is nil
    #
    def push(remote = nil, branch = nil, opts = nil)
      remote, branch, opts = normalize_push_args(remote, branch, opts)
      validate_push_args!(remote, branch, opts)

      first_result = push_refs(remote, branch, opts)
      return first_result.stdout unless push_tags_separately?(opts)

      push_tags(remote, opts).stdout
    end

    PULL_ALLOWED_OPTS = %i[allow_unrelated_histories].freeze

    def pull(remote = nil, branch = nil, opts = {})
      raise ArgumentError, 'You must specify a remote if a branch is specified' if remote.nil? && !branch.nil?

      assert_valid_opts(opts, PULL_ALLOWED_OPTS)
      allowed_opts = opts.slice(*PULL_ALLOWED_OPTS)
      positional_args = [remote, branch].compact
      Git::Commands::Pull.new(self).call(*positional_args, edit: false, progress: false, **allowed_opts).stdout
    end

    # Return the SHA of a tag reference
    #
    # Looks up the tag first in the local refs directory, then falls back to
    # `git show-ref`. Returns an empty string if the tag does not exist.
    #
    # @param tag_name [String] the tag name to look up
    #
    # @return [String] the SHA of the tag, or an empty string if not found
    #
    def tag_sha(tag_name)
      head = File.join(@git_dir, 'refs', 'tags', tag_name)
      return File.read(head).chomp if File.exist?(head)

      result = Git::Commands::ShowRef::List.new(self).call(tag_name, tags: true, hash: true)
      result.stdout
    end

    def repack
      command_capturing('repack', '-a', '-d')
    end

    def gc
      command_capturing('gc', '--prune', '--aggressive', '--auto')
    end

    # Execute git fsck to verify repository integrity
    #
    # @param objects [Array<String>] optional object identifiers to check
    # @param opts [Hash] command options (see {Git::Commands::Fsck#call})
    #
    # @return [Git::FsckResult] the structured result
    #
    # rubocop:disable Style/ArgumentsForwarding
    def fsck(*objects, **opts)
      result = Git::Commands::Fsck.new(self).call(*objects, progress: false, **opts)
      Git::Parsers::Fsck.parse(result.stdout)
    end
    # rubocop:enable Style/ArgumentsForwarding

    READ_TREE_ALLOWED_OPTS = %i[prefix].freeze

    def read_tree(treeish, opts = {})
      assert_valid_opts(opts, READ_TREE_ALLOWED_OPTS)
      allowed_opts = opts.slice(*READ_TREE_ALLOWED_OPTS)
      Git::Commands::ReadTree.new(self).call(treeish, **allowed_opts)
    end

    def write_tree
      Git::Commands::WriteTree.new(self).call.stdout
    end

    COMMIT_TREE_ALLOWED_OPTS = %i[p parent parents m message].freeze

    def commit_tree(tree, opts = {})
      assert_valid_opts(opts, COMMIT_TREE_ALLOWED_OPTS)
      actual_opts = normalize_commit_tree_opts(opts, tree)
      Git::Commands::CommitTree.new(self).call(tree, **actual_opts).stdout
    end

    def update_ref(ref, commit)
      Git::Commands::UpdateRef::Update.new(self).call(ref, commit)
    end

    def checkout_index(opts = {})
      paths = normalize_pathspecs(opts[:path_limiter], 'path_limiter')
      keyword_opts = opts.except(:path_limiter)
      Git::Commands::CheckoutIndex.new(self).call(*paths.to_a, **keyword_opts)
    end

    ARCHIVE_ALLOWED_OPTS = %i[prefix remote path format add_gzip].freeze

    # Creates an archive of the given tree-ish and writes it to a file
    #
    # Delegates to {Git::Commands::Archive} for CLI execution. Format coercion
    # (`tgz` → `tar` + gzip), temp file management, and gzip post-processing
    # remain in this adapter.
    #
    # @see https://git-scm.com/docs/git-archive git-archive
    #
    # @param sha [String] tree-ish to archive (commit, tag, branch, or tree SHA)
    #
    # @param file [String, nil] destination file path; a unique temp file is
    #   created and returned if `nil`
    #
    # @param opts [Hash] archive options
    #
    # @option opts [String] :prefix prefix to prepend to each filename in the archive
    #
    # @option opts [String] :remote URL of a remote repository to archive from
    #
    # @option opts [String] :path limit the archive to a path within the tree
    #
    # @option opts [String] :format archive format — `'tar'`, `'tgz'`, or `'zip'`
    #   (default: `'zip'`)
    #
    # @option opts [Boolean] :add_gzip wrap the archive in gzip compression
    #
    # @return [String] the path to the written archive file
    #
    # @raise [Git::FailedError] if `git archive` fails
    #
    def archive(sha, file = nil, opts = {})
      assert_valid_opts(opts, ARCHIVE_ALLOWED_OPTS)
      file ||= temp_file_name
      format, gzip = parse_archive_format_options(opts)

      command_opts = opts.slice(:prefix, :remote).merge(format: format)
      path_args = opts[:path] ? [opts[:path]] : []

      File.open(file, 'wb') do |f|
        Git::Commands::Archive.new(self).call(sha, *path_args, **command_opts, out: f)
      end
      apply_gzip(file) if gzip

      file
    end

    # returns the current version of git, as an Array of Fixnums.
    def current_command_version
      output = command_capturing('version').stdout
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

    COMMAND_CAPTURING_ARG_DEFAULTS = {
      in: nil,
      out: nil,
      err: nil,
      normalize: true,
      chomp: true,
      merge: false,
      chdir: nil,
      timeout: nil, # Don't set to Git.config.timeout here since it is mutable
      env: {},
      raise_on_failure: true
    }.freeze

    STATIC_GLOBAL_OPTS = %w[
      -c core.quotePath=true
      -c core.editor=false
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

    # Runs a git command and returns the result
    #
    # By default, raises {Git::FailedError} if the command exits with a non-zero
    # status. Pass `raise_on_failure: false` to suppress this behavior.
    #
    # @overload command_capturing(*args, **options_hash)
    #   Runs a git command and returns the result
    #
    #   Args should exclude the 'git' command itself and global options.
    #   Remember to splat the arguments if given as an array.
    #
    #   @example Run git log
    #     result = command_capturing('log', '--pretty=oneline')
    #     result.stdout #=> "abc123 First commit\ndef456 Second commit\n"
    #
    #   @example Using an array of arguments
    #     args = ['log', '--pretty=oneline']
    #     result = command_capturing(*args)
    #
    #   @example Suppress raising on failure
    #     result = command_capturing('show', 'nonexistent', raise_on_failure: false)
    #     result.status.success? #=> false
    #
    #   @param args [Array<String>] the command and its arguments
    #
    #   @param options_hash [Hash] the options to pass to the command
    #
    # @option options_hash [IO, nil] :in the IO object to use as stdin for the command, or nil to
    #   inherit the parent process stdin. Must be a real IO object with a file descriptor.
    #
    # @option options_hash [IO, String, #write, nil] :out the destination for captured stdout
    #
    # @option options_hash [IO, String, #write, nil] :err the destination for captured stderr
    #
    # @option options_hash [Boolean] :normalize true to normalize the output encoding to UTF-8
    #
    # @option options_hash [Boolean] :chomp true to remove trailing newlines from the output
    #
    # @option options_hash [Boolean] :merge true to merge stdout and stderr into a single output
    #
    # @option options_hash [String, nil] :chdir the directory to run the command in
    #
    # @option options_hash [Hash] :env additional environment variable overrides for this command
    #
    # @option options_hash [Boolean] :raise_on_failure (true) whether to raise on non-zero exit
    #
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
    # @note Individual command classes (under {Git::Commands}) can selectively
    #   expose `:timeout` and `:env` to their callers by declaring them as
    #   execution options in their Arguments DSL definition and forwarding
    #   them to this method. See {Git::Commands::Clone#call} for an example
    #   of a command that exposes `:timeout`.
    #
    # @see Git::CommandLine::Capturing#run
    # @see #command_line_capturing
    #
    # @return [Git::CommandLineResult] the result of the command
    #
    # @raise [ArgumentError] if an unknown option is passed
    #
    # @raise [Git::FailedError] if the command failed (when raise_on_failure is true)
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
    def command_capturing(*, **options_hash)
      options_hash = COMMAND_CAPTURING_ARG_DEFAULTS.merge(options_hash)
      options_hash[:timeout] ||= Git.config.timeout

      extra_options = options_hash.keys - COMMAND_CAPTURING_ARG_DEFAULTS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      env_overrides = options_hash.delete(:env)
      raise_on_failure = options_hash.delete(:raise_on_failure)
      command_line_capturing.run(*, raise_on_failure: raise_on_failure, env: env_overrides, **options_hash)
    end

    COMMAND_STREAMING_ARG_DEFAULTS = {
      in: nil,
      out: nil,
      err: nil,
      chdir: nil,
      timeout: nil,
      env: {},
      raise_on_failure: true
    }.freeze

    # Runs a git command using the streaming (non-capturing) execution path
    #
    # Unlike {#command_capturing}, stdout is NOT buffered in memory. It is
    # written only to the IO object provided via the `out:` option. Stderr is
    # captured internally via a StringIO for error diagnostics.
    #
    # Use this entry point when you want to stream large output (e.g. blob
    # content from cat-file) without creating memory pressure.
    #
    # @overload command_streaming(*args, **options_hash)
    #   @param args [Array<String>] the git command and its arguments
    #   @param options_hash [Hash] the options to pass to the command
    #
    # @option options_hash [IO, nil] :in stdin IO object
    # @option options_hash [#write, nil] :out destination for streamed stdout
    # @option options_hash [#write, nil] :err an optional additional destination to receive stderr output
    #   in real time. Stderr is always captured internally; when `err:` is supplied, writes are teed
    #   to both the internal buffer and this destination. `result.stderr` always reflects the internal capture.
    # @option options_hash [String, nil] :chdir the directory to run the command in
    # @option options_hash [Hash] :env additional environment variable overrides for this command
    # @option options_hash [Boolean] :raise_on_failure (true) whether to raise on non-zero exit
    # @option options_hash [Numeric, nil] :timeout the maximum seconds to wait for the command
    #   If nil, the global timeout from {Git::Config} is used.
    #
    # @return [Git::CommandLineResult] the result of the command
    #   `result.stdout` will always be `''` — stdout was streamed to `out:`.
    #   `result.stderr` contains any stderr output captured for diagnostics.
    #
    # @raise [ArgumentError] if an unknown option is passed
    # @raise [Git::FailedError] if the command failed (when raise_on_failure is true)
    # @raise [Git::SignaledError] if the command was signaled
    # @raise [Git::TimeoutError] if the command times out
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    #
    # @see Git::CommandLine::Streaming#run
    # @see #command_line_streaming
    #
    def command_streaming(*, **options_hash)
      options_hash = COMMAND_STREAMING_ARG_DEFAULTS.merge(options_hash)
      options_hash[:timeout] ||= Git.config.timeout

      extra_options = options_hash.keys - COMMAND_STREAMING_ARG_DEFAULTS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      env_overrides = options_hash.delete(:env)
      raise_on_failure = options_hash.delete(:raise_on_failure)
      command_line_streaming.run(*, raise_on_failure: raise_on_failure, env: env_overrides, **options_hash)
    end

    private

    # Build a result hash from clone options for Git::Base.new
    #
    # Parses the clone directory from the git command's stderr output, which
    # contains either:
    #   Cloning into '<directory>'...
    #   Cloning into bare repository '<directory>'...
    #
    # @param command_line_result [Git::CommandLineResult] the result of the git clone command
    #
    # @param opts [Hash] execution context options (:log, :git_ssh)
    #
    # @return [Hash] result hash with directory, log, and git_ssh keys
    #
    def build_clone_result(command_line_result, opts)
      clone_dir, bare = parse_clone_stderr(command_line_result.stderr)
      result = bare ? { repository: clone_dir } : { working_directory: clone_dir }
      result[:log] = opts[:log] if opts[:log]
      result[:git_ssh] = opts[:git_ssh] if opts.key?(:git_ssh)
      result
    end

    # Parse the clone directory and bare status from git clone's stderr output
    #
    # Git outputs the directory in an unencoded way (no `core.quotePath` or
    # similar escaping applies to clone's stderr message). The message format
    # is always:
    #
    #   Cloning into '<directory>'...
    #   Cloning into bare repository '<directory>'...
    #
    # Because the directory name is not escaped, a name containing the
    # literal sequence `'...` (single-quote followed by three dots) would
    # be ambiguous. In practice this is extremely unlikely.
    #
    # @param stderr [String] stderr output from git clone
    #
    # @return [Array(String, Boolean)] the clone directory and whether it's a bare repository
    #
    # @raise [Git::UnexpectedResultError] if the stderr output cannot be parsed
    #
    def parse_clone_stderr(stderr)
      match = stderr.match(/Cloning into (?:(bare repository) )?'(.+)'\.\.\./)
      raise Git::UnexpectedResultError, "Unable to determine clone directory from: #{stderr}" unless match

      [match[2], !match[1].nil?]
    end

    # Prefixes clone result path values with the chdir directory.
    #
    # Mutates the given result hash in place, updating any :working_directory
    # and :repository entries to be rooted under the provided +chdir+ directory.
    # If +chdir+ is nil, the hash is left unchanged.
    #
    # @param result [Hash] clone result hash containing path information
    # @param chdir [String, nil] directory under which the repository was cloned
    # @return [nil]
    #
    def prefix_clone_result_paths!(result, chdir)
      return unless chdir

      %i[working_directory repository].each do |key|
        result[key] = File.join(chdir, result[key]) if result.key?(key)
      end
    end

    # Handles the deprecated :path option for Git::Lib#clone.
    #
    # If opts contains :path, emits a deprecation warning and migrates the
    # value to :chdir (unless :chdir is already set). Mutates opts in place.
    #
    # @param opts [Hash] clone options, possibly containing :path
    # @return [nil]
    #
    def deprecate_clone_path_option!(opts)
      return unless opts.key?(:path)

      Git::Deprecation.warn('The :path option for Git::Lib#clone is deprecated, use :chdir instead')
      path = opts.delete(:path)
      opts[:chdir] ||= path
    end

    def deprecate_clone_recursive_option!(opts)
      return unless opts.key?(:recursive)

      Git::Deprecation.warn('The :recursive option for Git::Lib#clone is deprecated, use :recurse_submodules instead')
      opts[:recurse_submodules] = opts.delete(:recursive)
    end

    def deprecate_clone_remote_option!(opts)
      return unless opts.key?(:remote)

      Git::Deprecation.warn('The :remote option for Git::Lib#clone is deprecated, use :origin instead')
      opts[:origin] = opts.delete(:remote)
    end

    def deprecate_clone_options!(opts)
      deprecate_clone_path_option!(opts)
      deprecate_clone_recursive_option!(opts)
      deprecate_clone_remote_option!(opts)
    end

    def deprecate_commit_add_all_option!(opts)
      return unless opts.key?(:add_all)

      Git::Deprecation.warn('The :add_all option for Git::Lib#commit is deprecated, use :all instead')
      opts[:all] = opts.delete(:add_all)
    end

    # Extracts execution context options from clone options.
    #
    # @param opts [Hash] clone options
    # @return [Hash] hash with :log and :git_ssh keys if present
    #
    def extract_clone_execution_context_opts(opts)
      result = {}
      result[:log] = opts.delete(:log) if opts[:log]
      result[:git_ssh] = opts.delete(:git_ssh) if opts.key?(:git_ssh)
      result
    end

    # Translate legacy merge option names to new interface
    #
    # @param opts [Hash] options with possibly legacy keys
    # @return [Hash] options with new keys
    #
    def translate_merge_options(opts)
      result = opts.dup

      # :no_commit => true becomes :commit => false
      result[:commit] = false if result.delete(:no_commit)

      # :no_ff => true becomes :ff => false
      result[:ff] = false if result.delete(:no_ff)

      # :message => 'msg' becomes :m => 'msg' (git merge uses -m, not --message)
      result[:m] = result.delete(:message) if result.key?(:message)

      result
    end

    # Extract name-status data from --raw output lines
    #
    # Raw lines have the format:
    #   :old_mode new_mode old_sha new_sha status\tpath
    # or for renames/copies:
    #   :old_mode new_mode old_sha new_sha Rxx\told_path\tnew_path
    #
    # @param output [String] raw diff output
    #
    # @return [Hash] mapping of file paths to status tokens
    #
    def extract_name_status_from_raw(output)
      output.split("\n").each_with_object({}) do |line, memo|
        next unless line.start_with?(':')

        parts = line[1..].split(/\s+/, 5)
        status_and_paths = parts[4].split("\t")
        status = status_and_paths[0]
        path = status_and_paths.length > 2 ? status_and_paths[2] : status_and_paths[1]
        memo[unescape_quoted_path(path)] = status
      end
    end

    # Extract only the patch text from combined numstat + shortstat + patch output
    #
    # When {Git::Commands::Diff} is called with `patch: true, numstat: true, shortstat: true`,
    # the output contains numstat, shortstat, and patch sections. This method extracts
    # only the patch portion (starting at "diff --git").
    #
    # @param output [String] combined command output
    #
    # @return [String] only the patch text
    #
    def extract_patch_text(output)
      match = output.match(/^diff --git /m)
      match ? output[match.begin(0)..] : output
    end

    # Extract only the numstat lines from combined numstat + shortstat output
    #
    # When {Git::Commands::Diff} is called with `numstat: true, shortstat: true`,
    # the output contains numstat lines followed by a shortstat summary line. This method
    # filters out the shortstat line and empty lines, returning only the numstat lines.
    #
    # @param output [String] combined command output
    #
    # @return [Array<String>] only the numstat lines
    #
    def extract_numstat_lines(output)
      output.split("\n").reject { |l| l.empty? || l.match?(/^\s*\d+\s+files?\s+changed/) }
    end

    def build_args(opts, option_map)
      Git::ArgsBuilder.new(opts, option_map).build
    end

    def validate_tag_options!(opts)
      needs_message = %i[a annotate s sign u local_user].any? { |k| opts[k] }
      has_message = opts[:m] || opts[:message]

      return unless needs_message && !has_message

      raise ArgumentError, 'Cannot create an annotated or signed tag without a message.'
    end

    def delete_tag(name)
      result = Git::Commands::Tag::Delete.new(self).call(name)
      raise Git::FailedError, result if result.status.exitstatus.positive?

      result.stdout
    end

    def create_tag(name, target, opts)
      Git::Commands::Tag::Create.new(self).call(name, target, **opts).stdout
    end

    def initialize_from_base(base_object)
      @git_dir = base_object.repo.to_s
      @git_index_file = base_object.index&.to_s
      @git_work_dir = base_object.dir&.to_s
      @git_ssh = base_object.git_ssh
    end

    def initialize_from_hash(base_hash)
      @git_dir = base_hash[:repository]
      @git_index_file = base_hash[:index]
      @git_work_dir = base_hash[:working_directory]
      @git_ssh = base_hash.key?(:git_ssh) ? base_hash[:git_ssh] : :use_global_config
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

    def get_branch_state(branch_name)
      Git::Commands::RevParse.new(self).call(branch_name, verify: true, quiet: true)
      :active
    rescue Git::FailedError => e
      # An exit status of 1 with empty stderr from `rev-parse --verify`
      # indicates a ref that exists but does not yet point to a commit.
      raise unless e.result.status.exitstatus == 1 && e.result.stderr.empty?

      :unborn
    end

    def normalize_grep_opts(opts)
      opts = opts.dup
      opts[:pathspec] = opts.delete(:path_limiter) if opts.key?(:path_limiter)
      opts
    end

    def parse_grep_output(lines)
      lines.each_with_object(Hash.new { |h, k| h[k] = [] }) do |line, hsh|
        match = line.match(/\A(.*?):(\d+):(.*)/)
        next unless match

        _full, filename, line_num, text = match.to_a
        hsh[filename] << [line_num.to_i, text]
      end
    end

    def parse_diff_stats_output(lines)
      file_stats = parse_stat_lines(lines)
      build_final_stats_hash(file_stats)
    end

    def parse_stat_lines(lines)
      lines.map do |line|
        insertions_s, deletions_s, filename = split_status_line(line)
        {
          filename: filename,
          insertions: insertions_s.to_i,
          deletions: deletions_s.to_i
        }
      end
    end

    def split_status_line(line)
      parts = line.split("\t")
      parts[-1] = unescape_quoted_path(parts[-1]) if parts.any?
      parts
    end

    def parse_raw_diff_output(stdout)
      stdout.split("\n").each_with_object({}) do |line, memo|
        info, file = split_status_line(line)
        mode_src, mode_dest, sha_src, sha_dest, type = info.split
        memo[file] = {
          mode_index: mode_dest, mode_repo: mode_src.to_s[1, 7],
          path: file, sha_repo: sha_src, sha_index: sha_dest,
          type: type
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

    # Convert a StashInfo to the legacy [index, message] format
    #
    # The legacy format strips the "WIP on <branch>:" or "On <branch>:" prefix
    # from the message and returns only the suffix.
    #
    # @param info [Git::StashInfo] the stash info object
    # @return [Array(Integer, String)] `[index, message]` pair with prefix stripped
    #
    # @api private
    #
    def stash_info_to_legacy(info, index = info.index)
      full_message = info.message
      match_data = full_message.match(/^[^:]+:(.*)$/)
      message = match_data ? match_data[1] : full_message

      [index, message.strip]
    end

    # Streams the staged content of a file at a given index stage to an IO object
    #
    # Uses the streaming execution path so content is written directly to `out_io`
    # without being buffered in memory.
    #
    # @api private
    #
    # @param path [String] the path to the file in the index
    #
    # @param stage [Integer] the index stage to read (e.g., `1` ancestor, `2` ours, `3` theirs)
    #
    # @param out_io [IO] the `IO` object to stream the staged content into
    #
    # @return [IO] `out_io`, as passed in
    #
    # @raise [Git::FailedError] if the object does not exist or git exits non-zero
    #
    # @raise [Git::TimeoutError] if the command exceeds the configured timeout
    #
    def write_staged_content(path, stage, out_io)
      command_streaming('show', ":#{stage}:#{path}", out: out_io)
      out_io
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

    def validate_push_args!(remote, branch, opts)
      assert_valid_opts(opts, PUSH_ALLOWED_OPTS)
      raise ArgumentError, 'remote is required if branch is specified' if !remote && branch
    end

    def push_refs(remote, branch, opts)
      positionals = [remote, branch].compact
      Git::Commands::Push.new(self).call(*positionals, **opts.except(:tags))
    end

    def push_tags_separately?(opts)
      opts[:tags] && !opts[:mirror]
    end

    def push_tags(remote, opts)
      Git::Commands::Push.new(self).call(*[remote].compact, **opts)
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

    def apply_gzip(file)
      file_content = File.read(file)
      Zlib::GzipWriter.open(file) { |gz| gz.write(file_content) }
    end

    # Returns a hash of environment variable overrides for git commands
    #
    # This method builds a hash of environment variables that control git's behavior,
    # such as the git directory, working tree, and index file locations.
    #
    # @param additional_overrides [Hash] additional environment variables to set or unset
    #
    #   Keys should be environment variable names (String) and values should be either:
    #   * A String value to set the environment variable
    #   * `nil` to unset the environment variable
    #
    #   Per Process.spawn semantics, setting a key to `nil` will unset that environment
    #   variable, removing it from the environment passed to the git command.
    #
    # @return [Hash<String, String|nil>] environment variable overrides
    #
    # @example Basic usage with default environment variables
    #   env_overrides
    #   # => { 'GIT_DIR' => '/path/to/.git', 'GIT_WORK_TREE' => '/path/to/worktree', ... }
    #
    # @example Adding a custom environment variable
    #   env_overrides('GIT_TRACE' => '1')
    #   # => { 'GIT_DIR' => '/path/to/.git', ..., 'GIT_TRACE' => '1' }
    #
    # @example Unsetting an environment variable (used by worktree_command_line)
    #   env_overrides('GIT_INDEX_FILE' => nil)
    #   # => { 'GIT_DIR' => '/path/to/.git', 'GIT_WORK_TREE' => '/path/to/worktree',
    #   #      'GIT_INDEX_FILE' => nil, 'GIT_SSH' => <git_ssh_value>, 'LC_ALL' => 'en_US.UTF-8' }
    #   # When passed to Process.spawn, GIT_INDEX_FILE will be unset in the environment
    #
    # @see https://ruby-doc.org/core/Process.html#method-c-spawn Process.spawn
    #
    # @api private
    #
    def env_overrides(**additional_overrides)
      {
        'GIT_DIR' => @git_dir,
        'GIT_WORK_TREE' => @git_work_dir,
        'GIT_INDEX_FILE' => @git_index_file,
        'GIT_SSH' => resolved_git_ssh,
        'GIT_EDITOR' => 'true', # Use a no-op editor so Git skips interactive editing but continues
        'LC_ALL' => 'en_US.UTF-8'
      }.merge(additional_overrides)
    end

    # Resolve the git_ssh value to use for this instance
    #
    # @return [String, nil] the resolved git_ssh value
    #
    #   Returns the global config value if @git_ssh is the sentinel :use_global_config,
    #   otherwise returns @git_ssh (which may be nil or a string)
    #
    # @api private
    #
    def resolved_git_ssh
      return Git::Base.config.git_ssh if @git_ssh == :use_global_config

      @git_ssh
    end

    def global_opts
      [].tap do |global_opts|
        global_opts << "--git-dir=#{@git_dir}" unless @git_dir.nil?
        global_opts << "--work-tree=#{@git_work_dir}" unless @git_work_dir.nil?
        global_opts.concat(STATIC_GLOBAL_OPTS)
      end
    end

    # Returns the {Git::CommandLine::Capturing} instance used for capturing execution
    #
    # Memoized factory for the capturing execution path.  Instantiates
    # {Git::CommandLine::Capturing} with the current environment, binary path,
    # global options, and logger.
    #
    # @return [Git::CommandLine::Capturing]
    #
    # @see Git::CommandLine::Capturing#run
    #
    def command_line_capturing
      @command_line_capturing ||=
        Git::CommandLine::Capturing.new(env_overrides, Git::Base.config.binary_path, global_opts, @logger)
    end

    # Returns the {Git::CommandLine::Streaming} instance used for streaming execution
    #
    # Memoized factory for the streaming execution path.  Instantiates
    # {Git::CommandLine::Streaming} with the current environment, binary path,
    # global options, and logger.
    #
    # @return [Git::CommandLine::Streaming]
    #
    # @see Git::CommandLine::Streaming#run
    #
    def command_line_streaming
      @command_line_streaming ||=
        Git::CommandLine::Streaming.new(env_overrides, Git::Base.config.binary_path, global_opts, @logger)
    end

    # Validates the :count option for log commands.
    #
    def validate_log_count_option!(opts)
      return unless opts[:count] && !opts[:count].is_a?(Integer)

      raise ArgumentError, "The log count option must be an Integer but was #{opts[:count].inspect}"
    end

    # Builds the positional revision range argument(s) from opts for Git::Commands::Log
    #
    # @param opts [Hash]
    # @return [Array<String>] zero or one element array with the revision range expression
    def log_revision_range_args(opts)
      if opts[:between]
        ["#{opts[:between][0]}..#{opts[:between][1]}"]
      elsif opts[:object].is_a?(String)
        [opts[:object]]
      else
        []
      end
    end

    # Builds the common keyword options for Git::Commands::Log from opts
    #
    # @param opts [Hash]
    # @param extra [Hash] additional options to merge in (caller-specific)
    # @return [Hash] keyword arguments for Git::Commands::Log#call
    def log_base_call_options(opts, extra = {})
      {
        all: opts[:all],
        cherry: opts[:cherry],
        since: opts[:since],
        until: opts[:until],
        grep: opts[:grep],
        author: opts[:author],
        max_count: opts[:count],
        path: opts[:path_limiter] ? Array(opts[:path_limiter]) : nil
      }.merge(extra).compact
    end

    def run_log_command(revision_range_args, call_opts)
      log_or_empty_on_unborn do
        result = Git::Commands::Log.new(self).call(
          *revision_range_args,
          no_color: true, pretty: 'raw',
          **call_opts
        )
        process_commit_log_data(result.stdout.split("\n"))
      end
    end

    def log_or_empty_on_unborn
      yield
    rescue Git::FailedError => e
      raise unless e.result.status.exitstatus == 128 &&
                   e.result.stderr =~ /does not have any commits yet/

      []
    end

    def normalize_commit_tree_opts(opts, tree)
      opts.dup.tap do |actual_opts|
        actual_opts[:p] = actual_opts.delete(:parents) if actual_opts.key?(:parents)
        actual_opts[:p] = actual_opts.delete(:parent) if actual_opts.key?(:parent)
        actual_opts[:m] = actual_opts.delete(:message) if actual_opts.key?(:message)
        actual_opts[:m] = "commit tree #{tree}" if actual_opts[:m].nil?
      end
    end
  end
end
