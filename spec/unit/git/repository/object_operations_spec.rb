# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/object_operations'

# Integration-level coverage for Git::Repository::ObjectOperations is
# provided by spec/integration/git/repository/object_operations_spec.rb.
# The unit specs below cover the facade's own behavior: argument validation and
# delegation contract. Real git execution is covered by the integration spec.

RSpec.describe Git::Repository::ObjectOperations do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#cat_file_contents' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'without a block' do
      subject(:result) { described_instance.cat_file_contents('HEAD:README.md') }

      let(:contents_result) { command_result("# Hello\n") }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(contents_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with the object and p: true' do
        expect(raw_command).to receive(:call).with('HEAD:README.md', p: true).and_return(contents_result)
        result
      end

      it 'returns the stdout of the command as a String' do
        allow(raw_command).to receive(:call).with('HEAD:README.md', p: true).and_return(contents_result)
        expect(result).to eq("# Hello\n")
      end
    end

    context 'with a block' do
      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call) do |_object, **kwargs|
          kwargs[:out].write('content')
          command_result('')
        end
        described_instance.cat_file_contents('HEAD') { |_f| nil }
      end

      it 'calls Git::Commands::CatFile::Raw#call with object, p: true, and an out: File' do
        expect(raw_command).to receive(:call)
          .with('HEAD', p: true, out: instance_of(File))
          .and_return(command_result(''))
        described_instance.cat_file_contents('HEAD') { |_f| nil }
      end

      it 'streams content to a tempfile and yields the rewound file' do
        allow(raw_command).to receive(:call) do |_object, **kwargs|
          kwargs[:out].write('streamed content')
          command_result('')
        end

        yielded = nil
        described_instance.cat_file_contents('HEAD') { |f| yielded = f.read }

        expect(yielded).to eq('streamed content')
      end

      it 'returns the value returned by the block' do
        allow(raw_command).to receive(:call) do |_object, **kwargs|
          kwargs[:out].write('')
          command_result('')
        end

        result = described_instance.cat_file_contents('HEAD') { |_f| :block_return_value }

        expect(result).to eq(:block_return_value)
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_contents('--batch') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end
  end

  describe '#cat_file_size' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'with a valid object name' do
      subject(:result) { described_instance.cat_file_size('HEAD') }

      let(:size_result) { command_result("265\n") }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(size_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with the object and s: true' do
        expect(raw_command).to receive(:call).with('HEAD', s: true).and_return(size_result)
        result
      end

      it 'returns the size as an Integer' do
        allow(raw_command).to receive(:call).with('HEAD', s: true).and_return(size_result)
        expect(result).to eq(265)
      end
    end

    context 'with a treeish path reference' do
      subject(:result) { described_instance.cat_file_size('HEAD:README.md') }

      let(:size_result) { command_result("14\n") }

      it 'forwards the treeish reference to Git::Commands::CatFile::Raw#call' do
        expect(raw_command).to receive(:call).with('HEAD:README.md', s: true).and_return(size_result)
        result
      end

      it 'returns the size as an Integer' do
        allow(raw_command).to receive(:call).with('HEAD:README.md', s: true).and_return(size_result)
        expect(result).to eq(14)
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_size('--batch') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end
  end

  describe '#cat_file_type' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'with a commit reference' do
      subject(:result) { described_instance.cat_file_type('HEAD') }

      let(:type_result) { command_result("commit\n") }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(type_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with the object and t: true' do
        expect(raw_command).to receive(:call).with('HEAD', t: true).and_return(type_result)
        result
      end

      it 'returns the type as a String with no trailing newline' do
        allow(raw_command).to receive(:call).with('HEAD', t: true).and_return(type_result)
        expect(result).to eq('commit')
      end
    end

    context 'with a treeish path reference to a blob' do
      subject(:result) { described_instance.cat_file_type('HEAD:README.md') }

      let(:blob_result) { command_result("blob\n") }

      it 'forwards the treeish reference to Git::Commands::CatFile::Raw#call' do
        expect(raw_command).to receive(:call).with('HEAD:README.md', t: true).and_return(blob_result)
        result
      end

      it 'returns "blob"' do
        allow(raw_command).to receive(:call).with('HEAD:README.md', t: true).and_return(blob_result)
        expect(result).to eq('blob')
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_type('--batch') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end
  end

  describe '#cat_file_commit' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'with a single-parent commit' do
      subject(:result) { described_instance.cat_file_commit('HEAD') }

      let(:commit_body) do
        "tree abc123\nparent def456\nauthor A <a@example.com> 1 +0000\n" \
          "committer A <a@example.com> 1 +0000\n\nInitial commit\n"
      end
      let(:commit_result) { command_result(commit_body) }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(commit_result)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with type commit and the object' do
        expect(raw_command).to receive(:call).with('commit', 'HEAD').and_return(commit_result)
        result
      end

      it 'returns a Hash with the expected commit data' do
        allow(raw_command).to receive(:call).with('commit', 'HEAD').and_return(commit_result)
        expect(result).to include(
          'sha' => 'HEAD',
          'tree' => 'abc123',
          'parent' => ['def456'],
          'author' => 'A <a@example.com> 1 +0000',
          'committer' => 'A <a@example.com> 1 +0000',
          'message' => "Initial commit\n"
        )
      end
    end

    context 'with a root commit (no parent lines)' do
      subject(:result) { described_instance.cat_file_commit('abc123') }

      let(:commit_body) do
        "tree def456\nauthor A <a@example.com> 1 +0000\n" \
          "committer A <a@example.com> 1 +0000\n\nRoot commit\n"
      end

      it 'returns an empty parent array' do
        allow(raw_command).to receive(:call)
          .with('commit', 'abc123')
          .and_return(command_result(commit_body))
        expect(result).to include('parent' => [])
      end
    end

    context 'with a merge commit (multiple parents)' do
      subject(:result) { described_instance.cat_file_commit('HEAD') }

      let(:commit_body) do
        "tree abc123\nparent def456\nparent ghi789\nauthor A <a@example.com> 1 +0000\n" \
          "committer A <a@example.com> 1 +0000\n\nMerge branch 'feature'\n"
      end

      it 'returns all parent SHAs in the parent array' do
        allow(raw_command).to receive(:call)
          .with('commit', 'HEAD')
          .and_return(command_result(commit_body))
        expect(result).to include('parent' => %w[def456 ghi789])
      end
    end
  end

  describe '#cat_file_tag' do
    let(:raw_command) { instance_double(Git::Commands::CatFile::Raw) }

    before do
      allow(Git::Commands::CatFile::Raw).to receive(:new)
        .with(execution_context)
        .and_return(raw_command)
    end

    context 'with a valid annotated tag' do
      subject(:result) { described_instance.cat_file_tag('v1.0') }

      let(:tag_body) do
        "object deadbeef\ntype commit\ntag v1.0\ntagger A <a@example.com> 1 +0000\n\nRelease v1.0"
      end

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(command_result(tag_body))
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with type tag and the object' do
        expect(raw_command).to receive(:call).with('tag', 'v1.0').and_return(command_result(tag_body))
        result
      end

      it 'returns a Hash with name set to the object argument' do
        allow(raw_command).to receive(:call).with('tag', 'v1.0').and_return(command_result(tag_body))
        expect(result['name']).to eq('v1.0')
      end

      it 'returns a Hash with the parsed tag headers' do
        allow(raw_command).to receive(:call).with('tag', 'v1.0').and_return(command_result(tag_body))
        expect(result).to include(
          'object' => 'deadbeef',
          'type' => 'commit',
          'tag' => 'v1.0',
          'tagger' => 'A <a@example.com> 1 +0000'
        )
      end

      it 'returns a Hash with message including a trailing newline' do
        allow(raw_command).to receive(:call).with('tag', 'v1.0').and_return(command_result(tag_body))
        expect(result['message']).to eq("Release v1.0\n")
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_tag('--all') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--all'")
      end
    end
  end

  describe '#rev_parse' do
    let(:rev_parse_command) { instance_double(Git::Commands::RevParse) }

    before do
      allow(Git::Commands::RevParse).to receive(:new)
        .with(execution_context)
        .and_return(rev_parse_command)
    end

    context 'with a valid revision specifier' do
      subject(:result) { described_instance.rev_parse('HEAD') }

      let(:sha) { '9b9b31e704c0b85ffdd8d2af2ded85170a5af87d' }
      let(:rev_parse_result) { command_result(sha) }

      it 'constructs Git::Commands::RevParse with the execution context' do
        expect(Git::Commands::RevParse).to receive(:new).with(execution_context).and_return(rev_parse_command)
        allow(rev_parse_command).to receive(:call).and_return(rev_parse_result)
        result
      end

      it 'calls Git::Commands::RevParse#call with the revision, "--", and revs_only: true' do
        expect(rev_parse_command).to receive(:call).with('HEAD', '--', revs_only: true).and_return(rev_parse_result)
        result
      end

      it 'returns the stdout of the command as a String' do
        allow(rev_parse_command).to receive(:call).with('HEAD', '--', revs_only: true).and_return(rev_parse_result)
        expect(result).to eq(sha)
      end
    end

    context 'with an abbreviated SHA' do
      subject(:result) { described_instance.rev_parse('9b9b31e') }

      let(:sha) { '9b9b31e704c0b85ffdd8d2af2ded85170a5af87d' }
      let(:rev_parse_result) { command_result(sha) }

      it 'calls Git::Commands::RevParse#call with the abbreviated SHA' do
        expect(rev_parse_command).to receive(:call).with('9b9b31e', '--', revs_only: true).and_return(rev_parse_result)
        result
      end

      it 'returns the full SHA' do
        allow(rev_parse_command).to receive(:call).with('9b9b31e', '--', revs_only: true).and_return(rev_parse_result)
        expect(result).to eq(sha)
      end
    end
  end

  describe '#full_tree' do
    let(:ls_tree_command) { instance_double(Git::Commands::LsTree) }

    before do
      allow(Git::Commands::LsTree).to receive(:new)
        .with(execution_context)
        .and_return(ls_tree_command)
    end

    context 'with a tree SHA' do
      subject(:result) { described_instance.full_tree('abc1234') }

      let(:tree_output) do
        "100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tex_dir/ex.txt\n" \
          "100644 blob abcdef0123456789abcdef0123456789abcdef01\tlib/git.rb\n"
      end
      let(:tree_result) { command_result(tree_output) }

      it 'constructs Git::Commands::LsTree with the execution context' do
        expect(Git::Commands::LsTree).to receive(:new).with(execution_context).and_return(ls_tree_command)
        allow(ls_tree_command).to receive(:call).and_return(tree_result)
        result
      end

      it 'calls Git::Commands::LsTree#call with the sha and r: true' do
        expect(ls_tree_command).to receive(:call).with('abc1234', r: true).and_return(tree_result)
        result
      end

      it 'returns stdout split on newlines as an Array<String>' do
        allow(ls_tree_command).to receive(:call).with('abc1234', r: true).and_return(tree_result)
        expect(result).to eq([
                               "100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tex_dir/ex.txt",
                               "100644 blob abcdef0123456789abcdef0123456789abcdef01\tlib/git.rb"
                             ])
      end
    end

    context 'when the tree is empty' do
      subject(:result) { described_instance.full_tree('abc1234') }

      it 'returns an empty Array' do
        allow(ls_tree_command).to receive(:call).with('abc1234', r: true).and_return(command_result(''))
        expect(result).to eq([])
      end
    end
  end

  describe '#archive' do
    let(:archive_command) { instance_double(Git::Commands::Archive) }
    let(:archive_result) { command_result('') }

    before do
      allow(Git::Commands::Archive).to receive(:new)
        .with(execution_context)
        .and_return(archive_command)
      allow(archive_command).to receive(:call).and_return(archive_result)
    end

    context 'with no file path (temp file path)' do
      subject(:result) { described_instance.archive('HEAD').tap { |p| @tmp_archive = p } }

      after { File.unlink(@tmp_archive) if @tmp_archive && File.exist?(@tmp_archive) }

      it 'returns a non-nil String path' do
        expect(result).to be_a(String)
      end
    end

    context 'with an explicit output file' do
      let(:tmpfile) do
        t = Tempfile.new(['archive_unit', '.zip'])
        t.close # Release the handle so File.rename can atomically replace this path on all platforms
        t
      end

      after { tmpfile.close! }

      context 'with a treeish and an explicit file path' do
        subject(:result) { described_instance.archive('HEAD', tmpfile.path) }

        it 'constructs Git::Commands::Archive with the execution context' do
          expect(Git::Commands::Archive).to receive(:new).with(execution_context).and_return(archive_command)
          result
        end

        it 'calls Git::Commands::Archive#call with treeish, format: zip, and an out: File' do
          expect(archive_command).to receive(:call)
            .with('HEAD', format: 'zip', out: instance_of(File))
            .and_return(archive_result)
          result
        end

        it 'returns the given file path' do
          expect(result).to eq(tmpfile.path)
        end
      end

      context 'with format: tar' do
        subject(:result) { described_instance.archive('HEAD', tmpfile.path, format: 'tar') }

        it 'calls Git::Commands::Archive#call with format: tar' do
          expect(archive_command).to receive(:call)
            .with('HEAD', format: 'tar', out: instance_of(File))
            .and_return(archive_result)
          result
        end
      end

      context 'with format: tgz' do
        subject(:result) { described_instance.archive('v1.0', tmpfile.path, format: 'tgz') }

        it 'converts tgz to tar when calling Git::Commands::Archive#call' do
          expect(archive_command).to receive(:call)
            .with('v1.0', format: 'tar', out: instance_of(File))
            .and_return(archive_result)
          result
        end
      end

      context 'with add_gzip: true' do
        subject(:result) { described_instance.archive('HEAD', tmpfile.path, add_gzip: true) }

        it 'calls Git::Commands::Archive#call with format: zip (unchanged by add_gzip)' do
          expect(archive_command).to receive(:call)
            .with('HEAD', format: 'zip', out: instance_of(File))
            .and_return(archive_result)
          result
        end

        it 'returns the given file path' do
          expect(result).to eq(tmpfile.path)
        end
      end

      context 'with a prefix option' do
        subject(:result) { described_instance.archive('HEAD', tmpfile.path, format: 'tar', prefix: 'myproject/') }

        it 'forwards prefix to Git::Commands::Archive#call' do
          expect(archive_command).to receive(:call)
            .with('HEAD', format: 'tar', prefix: 'myproject/', out: instance_of(File))
            .and_return(archive_result)
          result
        end
      end

      context 'with a path option' do
        subject(:result) { described_instance.archive('HEAD', tmpfile.path, format: 'tar', path: 'src/') }

        it 'passes path as a positional argument to Git::Commands::Archive#call' do
          expect(archive_command).to receive(:call)
            .with('HEAD', 'src/', format: 'tar', out: instance_of(File))
            .and_return(archive_result)
          result
        end
      end

      context 'with a remote option' do
        subject(:result) { described_instance.archive('HEAD', tmpfile.path, remote: 'origin') }

        it 'forwards remote to Git::Commands::Archive#call' do
          expect(archive_command).to receive(:call)
            .with('HEAD', format: 'zip', remote: 'origin', out: instance_of(File))
            .and_return(archive_result)
          result
        end
      end

      context 'with an unknown option' do
        subject(:result) { described_instance.archive('HEAD', tmpfile.path, unknown_opt: true) }

        it 'raises ArgumentError before calling Git::Commands::Archive' do
          expect(Git::Commands::Archive).not_to receive(:new)
          expect { result }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a directory path as file' do
      it 'raises ArgumentError before calling Git::Commands::Archive' do
        expect(Git::Commands::Archive).not_to receive(:new)
        expect { described_instance.archive('HEAD', Dir.tmpdir) }.to raise_error(ArgumentError, /is a directory/)
      end
    end
  end

  describe '#grep' do
    let(:grep_command) { instance_double(Git::Commands::Grep) }

    before do
      allow(Git::Commands::Grep).to receive(:new)
        .with(execution_context)
        .and_return(grep_command)
    end

    context 'with a pattern and no options' do
      subject(:result) { described_instance.grep('TODO') }

      let(:grep_output) { "HEAD:src/foo.rb:12:# TODO: fix this\n" }
      let(:grep_result) { command_result(grep_output) }

      it 'constructs Git::Commands::Grep with the execution context' do
        expect(Git::Commands::Grep).to receive(:new).with(execution_context).and_return(grep_command)
        allow(grep_command).to receive(:call).and_return(grep_result)
        result
      end

      it 'calls Git::Commands::Grep#call with HEAD, the pattern, no_color, and line_number' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', no_color: true, line_number: true)
          .and_return(grep_result)
        result
      end

      it 'returns a Hash keyed by treeish:filename with [line_number, text] arrays' do
        allow(grep_command).to receive(:call).and_return(grep_result)
        expect(result).to eq('HEAD:src/foo.rb' => [[12, '# TODO: fix this']])
      end
    end

    context 'with a path_limiter String' do
      subject(:result) { described_instance.grep('TODO', 'src/') }

      it 'forwards pathspec as an Array to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', pathspec: ['src/'], no_color: true, line_number: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with a path_limiter Array' do
      subject(:result) { described_instance.grep('TODO', ['src/', 'lib/']) }

      it 'forwards pathspec as the same Array to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', pathspec: ['src/', 'lib/'], no_color: true, line_number: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with an :object option' do
      subject(:result) { described_instance.grep('TODO', nil, object: 'abc1234') }

      it 'uses the given object instead of HEAD' do
        expect(grep_command).to receive(:call)
          .with('abc1234', pattern: 'TODO', no_color: true, line_number: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :ignore_case option' do
      subject(:result) { described_instance.grep('todo', nil, ignore_case: true) }

      it 'forwards ignore_case to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'todo', ignore_case: true, no_color: true, line_number: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :i alias' do
      subject(:result) { described_instance.grep('todo', nil, i: true) }

      it 'forwards :i to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'todo', i: true, no_color: true, line_number: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :invert_match option' do
      subject(:result) { described_instance.grep('TODO', nil, invert_match: true) }

      it 'forwards invert_match to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', invert_match: true, no_color: true, line_number: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :extended_regexp option' do
      subject(:result) { described_instance.grep('foo|bar', nil, extended_regexp: true) }

      it 'forwards extended_regexp to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'foo|bar', extended_regexp: true, no_color: true, line_number: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'when no lines match (exit status 1, empty stderr)' do
      subject(:result) { described_instance.grep('NOMATCH') }

      let(:no_match_result) { command_result('', exitstatus: 1) }

      it 'returns an empty hash' do
        allow(grep_command).to receive(:call).and_return(no_match_result)
        expect(result).to eq({})
      end
    end

    context 'when git exits with status 1 and non-empty stderr (bad object reference)' do
      subject(:result) { described_instance.grep('TODO', nil, object: 'bad_ref') }

      let(:error_result) { command_result('', exitstatus: 1, stderr: "fatal: bad object bad_ref\n") }

      it 'raises Git::FailedError' do
        allow(grep_command).to receive(:call).and_return(error_result)
        expect { result }.to raise_error(Git::FailedError)
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.grep('TODO', nil, line_number: true) }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::Grep).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, 'Unknown options: line_number')
      end
    end
  end
end
