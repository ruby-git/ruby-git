# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/object_operations'
require 'git/execution_context/repository'

RSpec.describe Git::Repository::ObjectOperations, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', "# Hello World\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#cat_file_contents' do
    context 'with a blob via treeish path' do
      it 'returns the raw content of the blob as a String' do
        result = described_instance.cat_file_contents('HEAD:README.md')
        expect(result).to be_a(String)
        expect(result).to include('# Hello World')
      end
    end

    context 'with a commit object' do
      it 'returns the raw content of the commit as a String' do
        result = described_instance.cat_file_contents('HEAD')
        expect(result).to be_a(String)
        expect(result).to include('tree ')
        expect(result).to include('author ')
      end
    end

    context 'with a block' do
      it 'yields a File positioned at the start of the content' do
        yielded_content = nil
        described_instance.cat_file_contents('HEAD:README.md') do |f|
          yielded_content = f.read
        end
        expect(yielded_content).to eq("# Hello World\n")
      end

      it 'returns the value returned by the block' do
        result = described_instance.cat_file_contents('HEAD:README.md') { |_f| :my_value }
        expect(result).to eq(:my_value)
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_contents('--batch') }
          .to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_contents('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#cat_file_size' do
    context 'with a commit object' do
      it 'returns the size of the commit as an Integer' do
        result = described_instance.cat_file_size('HEAD')
        expect(result).to be_a(Integer)
        expect(result).to be_positive
      end
    end

    context 'with a blob via treeish path' do
      it 'returns the size of the blob' do
        result = described_instance.cat_file_size('HEAD:README.md')
        expect(result).to eq(File.read(File.join(repo.dir.to_s, 'README.md')).bytesize)
      end
    end

    context 'with a tree object' do
      it 'returns the size of the tree object as an Integer' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        result = described_instance.cat_file_size(tree_sha)
        expect(result).to be_a(Integer)
        expect(result).to be_positive
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_size('--batch') }
          .to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_size('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#cat_file_type' do
    context 'with a commit reference' do
      it 'returns "commit"' do
        expect(described_instance.cat_file_type('HEAD')).to eq('commit')
      end
    end

    context 'with a tree reference' do
      it 'returns "tree"' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        expect(described_instance.cat_file_type(tree_sha)).to eq('tree')
      end
    end

    context 'with a blob via treeish path' do
      it 'returns "blob"' do
        expect(described_instance.cat_file_type('HEAD:README.md')).to eq('blob')
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_type('--batch') }
          .to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_type('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#cat_file_commit' do
    context 'with HEAD' do
      subject(:result) { described_instance.cat_file_commit('HEAD') }

      it 'returns a Hash' do
        expect(result).to be_a(Hash)
      end

      it 'sets sha to the requested object name' do
        expect(result['sha']).to eq('HEAD')
      end

      it 'includes tree, parent, author, committer, and message keys' do
        expect(result).to include('tree', 'parent', 'author', 'committer', 'message')
      end

      it 'sets parent to an Array' do
        expect(result['parent']).to be_a(Array)
      end

      it 'sets message with a trailing newline' do
        expect(result['message']).to end_with("\n")
      end

      it 'sets message to the commit message used when the commit was created' do
        expect(result['message']).to eq("Initial commit\n")
      end
    end

    context 'when called with a commit SHA' do
      it 'sets sha to the given SHA string' do
        sha = repo.lib.rev_parse('HEAD')
        result = described_instance.cat_file_commit(sha)
        expect(result['sha']).to eq(sha)
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_commit('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#cat_file_tag' do
    before do
      repo.add_tag('v1.0', annotate: true, message: 'Release v1.0')
    end

    context 'with a valid annotated tag' do
      subject(:result) { described_instance.cat_file_tag('v1.0') }

      it 'returns a Hash' do
        expect(result).to be_a(Hash)
      end

      it 'sets name to the tag name passed by the caller' do
        expect(result['name']).to eq('v1.0')
      end

      it 'includes the expected keys' do
        expect(result).to include('name', 'object', 'type', 'tag', 'tagger', 'message')
      end

      it 'sets type to "commit"' do
        expect(result['type']).to eq('commit')
      end

      it 'sets tag to the tag name' do
        expect(result['tag']).to eq('v1.0')
      end

      it 'sets message to the tag message with a trailing newline' do
        expect(result['message']).to eq("Release v1.0\n")
      end

      it 'sets object to a 40-character SHA' do
        expect(result['object']).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_tag('--all') }
          .to raise_error(ArgumentError, "Invalid object: '--all'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_tag('nonexistent_tag') }
          .to raise_error(Git::FailedError)
      end
    end

    context 'with an annotated tag whose message is empty' do
      before do
        repo.add_tag('v2.0', annotate: true, message: '')
      end

      it 'returns a Hash without raising NoMethodError' do
        expect { described_instance.cat_file_tag('v2.0') }.not_to raise_error
      end

      it 'sets message to a single newline' do
        result = described_instance.cat_file_tag('v2.0')
        expect(result['message']).to eq("\n")
      end
    end
  end

  describe '#rev_parse' do
    context 'with HEAD' do
      it 'returns a 40-character lowercase hex SHA' do
        result = described_instance.rev_parse('HEAD')
        expect(result).to match(/\A[0-9a-f]{40}\z/)
      end

      it 'returns a String' do
        expect(described_instance.rev_parse('HEAD')).to be_a(String)
      end
    end

    context 'with an abbreviated SHA' do
      it 'expands the abbreviated SHA to the full 40-character SHA' do
        full_sha = repo.lib.rev_parse('HEAD')
        abbreviated = full_sha[0, 7]
        expect(described_instance.rev_parse(abbreviated)).to eq(full_sha)
      end
    end

    context 'with a tree object via rev-parse syntax' do
      it 'resolves the tree SHA' do
        result = described_instance.rev_parse('HEAD^{tree}')
        expect(result).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'when the revision is unknown' do
      it 'raises Git::FailedError' do
        expect { described_instance.rev_parse('NOTFOUND') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#tag_sha' do
    context 'when the tag exists' do
      before do
        repo.add_tag('v1.0')
      end

      it 'returns the SHA of the tagged commit as a String' do
        result = described_instance.tag_sha('v1.0')
        expect(result.chomp).to match(/\A[0-9a-f]{40}\z/)
      end

      it 'returns the same SHA as rev_parse for the tag' do
        expected = repo.lib.rev_parse('v1.0')
        result = described_instance.tag_sha('v1.0')
        expect(result.chomp).to eq(expected.chomp)
      end
    end

    context 'when the tag does not exist' do
      it 'returns an empty string' do
        expect(described_instance.tag_sha('nonexistent')).to eq('')
      end
    end
  end

  describe '#full_tree' do
    context 'with the tree SHA for a commit containing one file' do
      it 'returns an Array<String>' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        result = described_instance.full_tree(tree_sha)
        expect(result).to be_a(Array)
        expect(result).to all(be_a(String))
      end

      it 'returns one entry per file in the tree' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        result = described_instance.full_tree(tree_sha)
        expect(result.size).to eq(1)
      end

      it 'returns entries in the git ls-tree format <mode> <type> <object>\\t<file>' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        result = described_instance.full_tree(tree_sha)
        expect(result.first).to match(/\A\d{6} \w+ [0-9a-f]{40}\t\S+\z/)
      end
    end

    context 'with a treeish specifier (HEAD^{tree})' do
      it 'resolves and recurses into the tree' do
        result = described_instance.full_tree('HEAD^{tree}')
        expect(result).to be_a(Array)
        expect(result).not_to be_empty
      end
    end

    context 'when the sha does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.full_tree('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#tree_depth' do
    context 'with the tree SHA for a commit containing one file' do
      it 'returns the recursive entry count as an Integer' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        result = described_instance.tree_depth(tree_sha)
        expect(result).to be_a(Integer)
      end

      it 'returns one for the initial repository tree' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        result = described_instance.tree_depth(tree_sha)
        expect(result).to eq(1)
      end
    end

    context 'with a treeish specifier (HEAD^{tree})' do
      it 'returns a positive count' do
        result = described_instance.tree_depth('HEAD^{tree}')
        expect(result).to be_positive
      end
    end

    context 'when the sha does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.tree_depth('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#name_rev' do
    context 'with a commit SHA that has a symbolic name' do
      it 'returns a String' do
        sha = repo.lib.rev_parse('HEAD')
        result = described_instance.name_rev(sha)
        expect(result).to be_a(String)
      end

      it 'returns the symbolic name without a trailing newline' do
        sha = repo.lib.rev_parse('HEAD')
        result = described_instance.name_rev(sha)
        expect(result).not_to end_with("\n")
      end
    end

    context 'with a branch ref that resolves to a commit' do
      it 'returns a non-nil String' do
        result = described_instance.name_rev('HEAD')
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end

    context 'when commit_ish starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.name_rev('--tags') }
          .to raise_error(ArgumentError, "Invalid commit_ish: '--tags'")
      end
    end
  end

  describe '#ls_tree' do
    before do
      write_file('lib/git.rb', "# frozen_string_literal: true\n")
      repo.add('lib/git.rb')
      repo.commit('Add lib/git.rb')
    end

    context 'when listing a tree that contains a blob and a subtree' do
      it 'returns a Hash keyed by object type' do
        result = described_instance.ls_tree('HEAD')
        expect(result.keys).to contain_exactly('blob', 'tree', 'commit')
      end

      it 'includes the top-level blob in the blob sub-hash' do
        result = described_instance.ls_tree('HEAD')
        expect(result['blob']).to have_key('README.md')
      end

      it 'includes the subtree in the tree sub-hash' do
        result = described_instance.ls_tree('HEAD')
        expect(result['tree']).to have_key('lib')
      end

      it 'includes mode and sha values for each entry' do
        result = described_instance.ls_tree('HEAD')
        entry = result['blob']['README.md']
        expect(entry).to include(:mode, :sha)
        expect(entry[:mode]).to match(/\A\d{6}\z/)
        expect(entry[:sha]).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'with recursive: true' do
      it 'lists files inside subtrees' do
        result = described_instance.ls_tree('HEAD', recursive: true)
        expect(result['blob']).to have_key('lib/git.rb')
      end

      it 'does not include the subtree itself in the tree sub-hash' do
        result = described_instance.ls_tree('HEAD', recursive: true)
        expect(result['tree']).not_to have_key('lib')
      end
    end

    context 'with a path option' do
      it 'limits the listing to entries under the given path' do
        result = described_instance.ls_tree('HEAD', path: 'lib')
        expect(result['tree']).to have_key('lib')
        expect(result['blob']).not_to have_key('README.md')
      end
    end

    context 'with an unsupported option' do
      it 'raises ArgumentError' do
        expect { described_instance.ls_tree('HEAD', bogus: true) }.to raise_error(ArgumentError)
      end
    end

    context 'when the sha does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.ls_tree('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#archive' do
    context 'with no file argument (temp file)' do
      it 'returns a non-nil String path to a written file' do
        result = described_instance.archive('HEAD')
        expect(result).to be_a(String)
        expect(File.size(result)).to be_positive
      ensure
        File.delete(result) if result && File.exist?(result)
      end
    end

    context 'with an explicit output file' do
      let(:tmpfile) do
        t = Tempfile.new('archive_test')
        t.close # Release the handle so File.rename can atomically replace this path on all platforms
        t
      end

      after { tmpfile.close! }

      context 'with a commit treeish and a zip format' do
        it 'returns the given file path' do
          result = described_instance.archive('HEAD', tmpfile.path, format: 'zip')
          expect(result).to eq(tmpfile.path)
        end

        it 'writes a non-empty file' do
          described_instance.archive('HEAD', tmpfile.path, format: 'zip')
          expect(File.size(tmpfile.path)).to be_positive
        end
      end

      context 'with a tar format' do
        it 'writes a non-empty archive file' do
          described_instance.archive('HEAD', tmpfile.path, format: 'tar')
          expect(File.size(tmpfile.path)).to be_positive
        end
      end

      context 'with a tgz format' do
        it 'writes a gzip-compressed archive file' do
          described_instance.archive('HEAD', tmpfile.path, format: 'tgz')
          expect(File.size(tmpfile.path)).to be_positive
          # Verify the file is a valid gzip stream
          Zlib::GzipReader.open(tmpfile.path, &:read)
        end
      end

      context 'with a prefix option' do
        it 'writes a non-empty archive file' do
          described_instance.archive('HEAD', tmpfile.path, format: 'tar', prefix: 'myproject/')
          expect(File.size(tmpfile.path)).to be_positive
        end
      end

      context 'with add_gzip: true' do
        it 'writes a gzip-compressed archive file' do
          described_instance.archive('HEAD', tmpfile.path, format: 'tar', add_gzip: true)
          expect(File.size(tmpfile.path)).to be_positive
          Zlib::GzipReader.open(tmpfile.path, &:read)
        end
      end

      context 'with an unknown option' do
        it 'raises ArgumentError without calling git' do
          expect { described_instance.archive('HEAD', tmpfile.path, bad_opt: true) }
            .to raise_error(ArgumentError)
        end
      end

      context 'when the destination already exists with specific permissions' do
        before { skip 'POSIX file modes are not supported on Windows' if Gem.win_platform? }
        before { File.chmod(0o640, tmpfile.path) }

        it 'preserves the existing file mode on the written archive' do
          described_instance.archive('HEAD', tmpfile.path, format: 'zip')
          expect(File.stat(tmpfile.path).mode & 0o777).to eq(0o640)
        end
      end

      context 'when the archive command fails' do
        it 'leaves the existing destination file intact' do
          File.write(tmpfile.path, 'original content')
          expect { described_instance.archive('invalid-sha-does-not-exist', tmpfile.path) }
            .to raise_error(Git::FailedError)
          expect(File.read(tmpfile.path)).to eq('original content')
        end
      end

      context 'when dest is a symlink to an existing non-directory file' do
        let(:link_target) { Tempfile.new('archive_target').tap(&:close) }
        let(:link_path) do
          File.join(File.dirname(tmpfile.path), "archive_symlink_#{Process.pid}")
        end

        before do
          File.symlink(link_target.path, link_path)
        rescue NotImplementedError, SystemCallError
          skip 'Symlinks are not supported or not permitted on this platform'
        end

        after do
          File.unlink(link_path) if File.exist?(link_path) || File.symlink?(link_path)
          link_target.close!
        end

        it 'replaces the symlink with a regular archive file' do
          described_instance.archive('HEAD', link_path, format: 'zip')
          expect(File.symlink?(link_path)).to be(false)
          expect(File.size(link_path)).to be_positive
        end

        it 'does not modify the symlink target' do
          target_size_before = File.size(link_target.path)
          described_instance.archive('HEAD', link_path, format: 'zip')
          expect(File.size(link_target.path)).to eq(target_size_before)
        end
      end
    end

    context 'with a directory path as file' do
      it 'raises ArgumentError without creating an archive file' do
        expect { described_instance.archive('HEAD', Dir.tmpdir) }
          .to raise_error(ArgumentError, /is a directory/)
      end
    end
  end

  describe '#grep' do
    before do
      write_file('src/foo.rb', "# TODO: fix this\nsome other line\n")
      write_file('src/bar.rb', "# NOTE: nothing here\n# TODO: also here\n")
      repo.add('.')
      repo.commit('Add files')
    end

    context 'with a pattern that matches files' do
      it 'returns a Hash with treeish:filename keys' do
        result = described_instance.grep('TODO')
        expect(result).to be_a(Hash)
        expect(result.keys).to all(match(%r{\AHEAD:src/}))
      end

      it 'maps each key to an array of [line_number, text] pairs' do
        result = described_instance.grep('TODO')
        result.each_value do |matches|
          expect(matches).to all(match([be_a(Integer), be_a(String)]))
        end
      end

      it 'includes the correct line number and text for each match' do
        result = described_instance.grep('TODO')
        foo_matches = result['HEAD:src/foo.rb']
        expect(foo_matches).to include([1, '# TODO: fix this'])
      end

      it 'preserves filenames and text containing colon-number-colon sequences' do
        write_file('src/foo:42:bar.rb', "matched text:13:still text\n")
        repo.add('.')
        repo.commit('Add colon filename')

        result = described_instance.grep('matched')

        expect(result['HEAD:src/foo:42:bar.rb']).to eq([[1, 'matched text:13:still text']])
      end
    end

    context 'with a path_limiter String that restricts results' do
      it 'returns only matches under the given path' do
        result = described_instance.grep('TODO', 'src/foo.rb')
        expect(result.keys).to eq(['HEAD:src/foo.rb'])
      end
    end

    context 'with a path_limiter Array' do
      it 'returns matches from all paths in the array' do
        result = described_instance.grep('TODO', ['src/foo.rb', 'src/bar.rb'])
        expect(result.keys).to contain_exactly('HEAD:src/foo.rb', 'HEAD:src/bar.rb')
      end
    end

    context 'with :ignore_case option' do
      it 'returns matches regardless of case' do
        result = described_instance.grep('todo', nil, ignore_case: true)
        expect(result).not_to be_empty
      end

      it 'returns no matches without ignore_case when pattern case differs' do
        result = described_instance.grep('todo')
        expect(result).to be_empty
      end
    end

    context 'with :invert_match option' do
      it 'returns lines that do not match the pattern' do
        result = described_instance.grep('TODO', 'src/foo.rb', invert_match: true)
        expect(result['HEAD:src/foo.rb']).to include([2, 'some other line'])
        expect(result['HEAD:src/foo.rb'].map(&:last)).not_to include(match(/TODO/))
      end
    end

    context 'with :extended_regexp option' do
      it 'matches using POSIX extended regular expressions' do
        result = described_instance.grep('TODO|NOTE', nil, extended_regexp: true)
        expect(result.keys).to contain_exactly('HEAD:src/foo.rb', 'HEAD:src/bar.rb')
      end
    end

    context 'with :object option pointing to a specific commit' do
      it 'searches in that commit instead of HEAD' do
        sha = repo.lib.rev_parse('HEAD')
        result = described_instance.grep('TODO', nil, object: sha)
        expect(result).not_to be_empty
      end
    end

    context 'when no lines match' do
      it 'returns an empty hash' do
        result = described_instance.grep('NOMATCH_UNIQUE_XYZ')
        expect(result).to eq({})
      end
    end

    context 'with an unknown option' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.grep('TODO', nil, line_number: true) }
          .to raise_error(ArgumentError, 'Unknown options: line_number')
      end
    end

    context 'with an invalid object reference' do
      it 'raises Git::FailedError' do
        expect { described_instance.grep('TODO', nil, object: 'nonexistent_ref') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  # Integration tests for #gblob, #gcommit, #gtree, #tag, and #object are
  # intentionally omitted. All five are one-line delegators to Git::Object.new
  # or Git::Object::Tag.new — there is no facade-level orchestration or
  # post-processing. The underlying git operations (cat-file, show-ref) are
  # already exercised by the #cat_file_type, #cat_file_contents, and #tag_sha
  # integration tests above. Unit tests in
  # spec/unit/git/repository/object_operations_spec.rb verify the delegation
  # contract and argument forwarding.
end
