# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/object_operations'

RSpec.describe Git::Repository::ObjectOperations, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', "# Hello World\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#cat_file_contents' do
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
  end

  describe '#cat_file_size' do
    context 'with a blob via treeish path' do
      it 'returns the size of the blob' do
        result = described_instance.cat_file_size('HEAD:README.md')
        expect(result).to eq(File.read(File.join(repo.dir.to_s, 'README.md')).bytesize)
      end
    end
  end

  describe '#cat_file_type' do
    context 'with a commit reference' do
      it 'returns "commit"' do
        expect(described_instance.cat_file_type('HEAD')).to eq('commit')
      end
    end
  end

  describe '#cat_file_commit' do
    context 'with HEAD' do
      subject(:result) { described_instance.cat_file_commit('HEAD') }

      it 'sets sha to the requested object name' do
        expect(result['sha']).to eq('HEAD')
      end

      it 'includes tree, parent, author, committer, and message keys' do
        expect(result).to include('tree', 'parent', 'author', 'committer', 'message')
      end

      it 'sets message to the commit message used when the commit was created' do
        expect(result['message']).to eq("Initial commit\n")
      end
    end

    context 'when called with a commit SHA' do
      it 'sets sha to the given SHA string' do
        sha = repo.rev_parse('HEAD')
        result = described_instance.cat_file_commit(sha)
        expect(result['sha']).to eq(sha)
      end
    end

    context 'with a real SSH-signed commit',
            if: !Gem.win_platform?,
            skip: unless_git('2.34', 'SSH commit signing') || unless_command('ssh-keygen', 'SSH commit signing') do
      let(:ssh_key_file) { File.join(repo_dir, '.git', 'test-key') }

      before do
        system('ssh-keygen', '-t', 'ed25519', '-N', '', '-C', 'test key', '-f', ssh_key_file,
               out: File::NULL, err: File::NULL, exception: true)
        repo.config_set('gpg.format', 'ssh')
        repo.config_set('user.signingkey', ssh_key_file)

        write_file('SIGNED.md', '# Signed commit content')
        repo.add('SIGNED.md')
        execution_context.command_capturing('commit', '-S', '-m', 'Signed, sealed, delivered')
      end

      it 'parses the gpgsig header as an SSH signature and the message correctly' do
        result = described_instance.cat_file_commit('HEAD')

        expect(result['gpgsig']).to match(/-----BEGIN SSH SIGNATURE-----.*-----END SSH SIGNATURE-----/m)
        expect(result['message']).to eq("Signed, sealed, delivered\n")
      end
    end
  end

  describe '#cat_file_tag' do
    before do
      repo.tag_add('v1.0', annotate: true, message: 'Release v1.0')
    end

    context 'with a valid annotated tag' do
      subject(:result) { described_instance.cat_file_tag('v1.0') }

      it 'sets name to the tag name passed by the caller' do
        expect(result['name']).to eq('v1.0')
      end

      it 'includes the expected keys' do
        expect(result).to include('name', 'object', 'type', 'tag', 'tagger', 'message')
      end

      it 'sets message to the tag message with a trailing newline' do
        expect(result['message']).to eq("Release v1.0\n")
      end

      it 'sets object to a 40-character SHA' do
        expect(result['object']).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'with an annotated tag whose message is empty' do
      before do
        repo.tag_add('v2.0', annotate: true, message: '')
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

  describe '#tag_sha' do
    context 'when the tag exists' do
      before do
        repo.tag_add('v1.0')
      end

      it 'returns the SHA of the tagged commit as a String' do
        result = described_instance.tag_sha('v1.0')
        expect(result.chomp).to match(/\A[0-9a-f]{40}\z/)
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
      it 'returns one entry per file in the tree' do
        tree_sha = repo.rev_parse('HEAD^{tree}')
        result = described_instance.full_tree(tree_sha)
        expect(result.size).to eq(1)
      end
    end
  end

  describe '#tree_depth' do
    context 'with the tree SHA for a commit containing one file' do
      it 'returns the recursive entry count as an Integer' do
        tree_sha = repo.rev_parse('HEAD^{tree}')
        result = described_instance.tree_depth(tree_sha)
        expect(result).to be_a(Integer)
      end

      it 'returns one for the initial repository tree' do
        tree_sha = repo.rev_parse('HEAD^{tree}')
        result = described_instance.tree_depth(tree_sha)
        expect(result).to eq(1)
      end
    end
  end

  describe '#name_rev' do
    context 'with a commit SHA that has a symbolic name' do
      it 'returns the symbolic name without a trailing newline' do
        sha = repo.rev_parse('HEAD')
        result = described_instance.name_rev(sha)
        expect(result).not_to end_with("\n")
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

      context 'with a tgz format' do
        it 'writes a gzip-compressed archive file' do
          described_instance.archive('HEAD', tmpfile.path, format: 'tgz')
          expect(File.size(tmpfile.path)).to be_positive
          # Verify the file is a valid gzip stream
          Zlib::GzipReader.open(tmpfile.path, &:read)
        end
      end

      context 'with add_gzip: true' do
        it 'writes a gzip-compressed archive file' do
          described_instance.archive('HEAD', tmpfile.path, format: 'tar', add_gzip: true)
          expect(File.size(tmpfile.path)).to be_positive
          Zlib::GzipReader.open(tmpfile.path, &:read)
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
    end

    context 'with a filename containing colon-number-colon text' do
      before do
        skip 'Colon characters are not supported in Windows filenames' if Gem.win_platform?

        write_file('src/foo:42:bar.rb', "# TODO: colon filename\n")
        repo.add('.')
        repo.commit('Add colon-number filename')
      end

      it 'keeps the full filename in the grep result key' do
        result = described_instance.grep('TODO', 'src/foo:42:bar.rb')

        expect(result).to eq(
          'HEAD:src/foo:42:bar.rb' => [[1, '# TODO: colon filename']]
        )
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
        sha = repo.rev_parse('HEAD')
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
  end

  # Integration tests for #gblob, #gcommit, #gtree, #tag, and #object are
  # intentionally omitted. All five are one-line delegators to Git::Object.new
  # or Git::Object::Tag.new — there is no facade-level orchestration or
  # post-processing. The underlying git operations (cat-file, show-ref) are
  # already exercised by the #cat_file_type, #cat_file_contents, and #tag_sha
  # integration tests above. Unit tests in
  # spec/unit/git/repository/object_operations_spec.rb verify the delegation
  # contract and argument forwarding.

  describe '#tag_add' do
    context 'with no target and no options' do
      it 'creates a lightweight tag on HEAD' do
        tag = described_instance.tag_add('v1.0.0')
        expect(tag).to be_a(Git::Object::Tag)
        expect(tag.name).to eq('v1.0.0')
        expect(tag.annotated?).to be(false)
      end
    end

    context 'with a target commit' do
      it 'creates the tag pointing at the given commit' do
        head_sha = described_instance.rev_parse('HEAD')
        tag = described_instance.tag_add('v1.0.0', head_sha)
        expect(tag.objectish).to eq(head_sha)
      end
    end

    context 'with annotate and a message' do
      it 'creates an annotated tag carrying the message' do
        tag = described_instance.tag_add('v1.0.0', annotate: true, message: 'Release 1.0.0')
        expect(tag.annotated?).to be(true)
        expect(tag.message).to eq('Release 1.0.0')
      end
    end

    # Facade-owned validation (annotated/signed without a message, unsupported
    # options) and command error wrapping (tagging an existing name without
    # :force) are pure-Ruby or command concerns with no added end-to-end signal;
    # they are covered by the unit spec and command integration specs.
    context 'when the tag already exists' do
      before { described_instance.tag_add('v1.0.0') }

      it 'replaces the existing tag when force is given' do
        replaced = described_instance.tag_add('v1.0.0', force: true, annotate: true, message: 'replaced')
        expect(replaced.annotated?).to be(true)
        expect(replaced.message).to eq('replaced')
      end
    end
  end
end
