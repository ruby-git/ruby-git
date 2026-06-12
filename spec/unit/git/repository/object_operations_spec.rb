# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/object_operations'
require 'git/commands/show_ref/verify'
require 'git/parsers/cat_file'
require 'git/parsers/grep'
require 'git/parsers/ls_tree'

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

    context 'when object is nil' do
      it 'does not raise ArgumentError' do
        allow(raw_command).to receive(:call).with(nil, p: true).and_return(command_result("content\n"))
        expect { described_instance.cat_file_contents(nil) }.not_to raise_error
      end
    end
  end

  describe '#object_contents' do
    it 'is an alias for #cat_file_contents' do
      expect(described_class.instance_method(:object_contents))
        .to eq(described_class.instance_method(:cat_file_contents))
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

    context 'when object is nil' do
      it 'does not raise ArgumentError' do
        allow(raw_command).to receive(:call).with(nil, s: true).and_return(command_result("0\n"))
        expect { described_instance.cat_file_size(nil) }.not_to raise_error
      end
    end
  end

  describe '#object_size' do
    it 'is an alias for #cat_file_size' do
      expect(described_class.instance_method(:object_size)).to eq(described_class.instance_method(:cat_file_size))
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

    context 'when object is nil' do
      it 'does not raise ArgumentError' do
        allow(raw_command).to receive(:call).with(nil, t: true).and_return(command_result("commit\n"))
        expect { described_instance.cat_file_type(nil) }.not_to raise_error
      end
    end
  end

  describe '#object_type' do
    it 'is an alias for #cat_file_type' do
      expect(described_class.instance_method(:object_type)).to eq(described_class.instance_method(:cat_file_type))
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
      let(:parsed_commit) { { 'sha' => 'HEAD', 'tree' => 'abc123', 'parent' => ['def456'] } }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(commit_result)
        allow(Git::Parsers::CatFile).to receive(:parse_commit).and_return(parsed_commit)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with type commit and the object' do
        expect(raw_command).to receive(:call).with('commit', 'HEAD').and_return(commit_result)
        allow(Git::Parsers::CatFile).to receive(:parse_commit).and_return(parsed_commit)
        result
      end

      it 'delegates to Git::Parsers::CatFile.parse_commit with split lines and the object name' do
        allow(raw_command).to receive(:call).with('commit', 'HEAD').and_return(commit_result)
        expect(Git::Parsers::CatFile).to receive(:parse_commit)
          .with(commit_body.split("\n"), 'HEAD')
          .and_return(parsed_commit)
        result
      end

      it 'returns the value from Git::Parsers::CatFile.parse_commit' do
        allow(raw_command).to receive(:call).with('commit', 'HEAD').and_return(commit_result)
        allow(Git::Parsers::CatFile).to receive(:parse_commit).and_return(parsed_commit)
        expect(result).to eq(parsed_commit)
      end
    end
  end

  describe '#commit_data' do
    it 'is an alias for #cat_file_commit' do
      expect(described_class.instance_method(:commit_data)).to eq(described_class.instance_method(:cat_file_commit))
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
      let(:parsed_tag) { { 'name' => 'v1.0', 'object' => 'deadbeef', 'type' => 'commit' } }

      it 'constructs Git::Commands::CatFile::Raw with the execution context' do
        expect(Git::Commands::CatFile::Raw).to receive(:new).with(execution_context).and_return(raw_command)
        allow(raw_command).to receive(:call).and_return(command_result(tag_body))
        allow(Git::Parsers::CatFile).to receive(:parse_tag).and_return(parsed_tag)
        result
      end

      it 'calls Git::Commands::CatFile::Raw#call with type tag and the object' do
        expect(raw_command).to receive(:call).with('tag', 'v1.0').and_return(command_result(tag_body))
        allow(Git::Parsers::CatFile).to receive(:parse_tag).and_return(parsed_tag)
        result
      end

      it 'delegates to Git::Parsers::CatFile.parse_tag with split lines and the object name' do
        allow(raw_command).to receive(:call).with('tag', 'v1.0').and_return(command_result(tag_body))
        expect(Git::Parsers::CatFile).to receive(:parse_tag)
          .with(tag_body.split("\n"), 'v1.0')
          .and_return(parsed_tag)
        result
      end

      it 'returns the value from Git::Parsers::CatFile.parse_tag' do
        allow(raw_command).to receive(:call).with('tag', 'v1.0').and_return(command_result(tag_body))
        allow(Git::Parsers::CatFile).to receive(:parse_tag).and_return(parsed_tag)
        expect(result).to eq(parsed_tag)
      end
    end

    context 'when object starts with a hyphen' do
      subject(:result) { described_instance.cat_file_tag('--all') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::CatFile::Raw).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid object: '--all'")
      end
    end

    context 'when object is nil' do
      it 'does not raise ArgumentError' do
        allow(raw_command).to receive(:call).with('tag', nil).and_return(command_result(''))
        allow(Git::Parsers::CatFile).to receive(:parse_tag).and_return({})
        expect { described_instance.cat_file_tag(nil) }.not_to raise_error
      end
    end
  end

  describe '#tag_data' do
    it 'is an alias for #cat_file_tag' do
      expect(described_class.instance_method(:tag_data)).to eq(described_class.instance_method(:cat_file_tag))
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

  describe '#revparse' do
    it 'is an alias for #rev_parse' do
      expect(described_instance.method(:revparse)).to eq(described_instance.method(:rev_parse))
    end
  end

  describe '#tag_sha' do
    let(:show_ref_list_command) { instance_double(Git::Commands::ShowRef::List) }
    let(:git_dir) { '/fake/.git' }
    let(:tags_dir) { File.expand_path(File.join(git_dir, 'refs', 'tags')) }
    let(:tag_ref_path) { File.expand_path(File.join(tags_dir, 'v1.0')) }

    before do
      allow(execution_context).to receive(:git_dir).and_return(git_dir)
      allow(Git::Commands::ShowRef::List).to receive(:new)
        .with(execution_context)
        .and_return(show_ref_list_command)
    end

    context 'when the loose ref file exists under refs/tags/' do
      before do
        allow(File).to receive(:file?).with(tag_ref_path).and_return(true)
        allow(File).to receive(:read).with(tag_ref_path).and_return("abc1234\n")
      end

      it 'reads the SHA directly from the file without forking a git process' do
        expect(described_instance.tag_sha('v1.0')).to eq('abc1234')
        expect(Git::Commands::ShowRef::List).not_to have_received(:new)
      end
    end

    context 'when the loose ref path is a directory (e.g. a namespaced tag prefix like "release")' do
      before do
        allow(File).to receive(:file?).with(tag_ref_path).and_return(false)
        allow(show_ref_list_command).to receive(:call)
          .and_return(command_result('', exitstatus: 1))
      end

      it 'does not attempt to read the directory' do
        expect(File).not_to receive(:read)
        described_instance.tag_sha('v1.0')
      end

      it 'falls through to git show-ref and returns an empty string' do
        expect(described_instance.tag_sha('v1.0')).to eq('')
      end
    end

    context 'when the tag name contains path traversal sequences' do
      before do
        allow(show_ref_list_command).to receive(:call)
          .and_return(command_result('', exitstatus: 1))
      end

      it 'does not read from the filesystem' do
        expect(File).not_to receive(:read)
        described_instance.tag_sha('../../config')
      end

      it 'falls through to git show-ref and returns an empty string' do
        expect(described_instance.tag_sha('../../config')).to eq('')
      end
    end

    context 'when the loose ref file does not exist (packed ref or missing tag)' do
      before do
        allow(File).to receive(:file?).with(tag_ref_path).and_return(false)
      end

      it 'constructs Git::Commands::ShowRef::List with the execution context' do
        allow(show_ref_list_command).to receive(:call)
          .and_return(command_result("abc1234 refs/tags/v1.0\n"))

        expect(Git::Commands::ShowRef::List).to receive(:new)
          .with(execution_context)
          .and_return(show_ref_list_command)

        described_instance.tag_sha('v1.0')
      end

      it 'calls git show-ref with the full tag ref pattern' do
        expect(show_ref_list_command).to receive(:call)
          .with('refs/tags/v1.0')
          .and_return(command_result("abc1234 refs/tags/v1.0\n"))

        described_instance.tag_sha('v1.0')
      end

      it 'returns the SHA when the tag exists' do
        allow(show_ref_list_command).to receive(:call)
          .and_return(command_result("abc1234 refs/tags/v1.0\n"))

        expect(described_instance.tag_sha('v1.0')).to eq('abc1234')
      end

      it 'returns only the exact-match SHA when output contains partial-match refs' do
        allow(show_ref_list_command).to receive(:call)
          .and_return(command_result("abc1234 refs/tags/v1.0\ndef5678 refs/tags/v1.0.1\n"))

        expect(described_instance.tag_sha('v1.0')).to eq('abc1234')
      end

      it 'returns an empty string when the tag is not found (exit status 1)' do
        allow(show_ref_list_command).to receive(:call)
          .and_return(command_result('', exitstatus: 1))

        expect(described_instance.tag_sha('v1.0')).to eq('')
      end

      it 're-raises Git::FailedError for operational failures (e.g. not a git repository)' do
        allow(show_ref_list_command).to receive(:call)
          .and_raise(Git::FailedError.new(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128)))

        expect { described_instance.tag_sha('v1.0') }.to raise_error(Git::FailedError)
      end

      it 'returns an empty string when show-ref exits 0 but no line matches the exact ref' do
        allow(show_ref_list_command).to receive(:call)
          .and_return(command_result("def5678 refs/tags/v1.0.1\n"))

        expect(described_instance.tag_sha('v1.0')).to eq('')
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

  describe '#tree_depth' do
    let(:ls_tree_command) { instance_double(Git::Commands::LsTree) }

    before do
      allow(Git::Commands::LsTree).to receive(:new)
        .with(execution_context)
        .and_return(ls_tree_command)
    end

    context 'with a tree SHA' do
      subject(:result) { described_instance.tree_depth('abc1234') }

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

      it 'returns the number of recursive tree entries as an Integer' do
        allow(ls_tree_command).to receive(:call).with('abc1234', r: true).and_return(tree_result)
        expect(result).to eq(2)
      end
    end

    context 'when the tree is empty' do
      subject(:result) { described_instance.tree_depth('abc1234') }

      it 'returns 0' do
        allow(ls_tree_command).to receive(:call).with('abc1234', r: true).and_return(command_result(''))
        expect(result).to eq(0)
      end
    end
  end

  describe '#name_rev' do
    let(:name_rev_command) { instance_double(Git::Commands::NameRev) }

    before do
      allow(Git::Commands::NameRev).to receive(:new)
        .with(execution_context)
        .and_return(name_rev_command)
    end

    context 'with a valid commit SHA' do
      subject(:result) { described_instance.name_rev('abc1234') }

      let(:name_rev_result) { command_result("abc1234 main~5\n") }

      it 'constructs Git::Commands::NameRev with the execution context' do
        expect(Git::Commands::NameRev).to receive(:new).with(execution_context).and_return(name_rev_command)
        allow(name_rev_command).to receive(:call).and_return(name_rev_result)
        result
      end

      it 'calls Git::Commands::NameRev#call with the commit_ish' do
        expect(name_rev_command).to receive(:call).with('abc1234').and_return(name_rev_result)
        result
      end

      it 'returns the symbolic name (second word of stdout)' do
        allow(name_rev_command).to receive(:call).with('abc1234').and_return(name_rev_result)
        expect(result).to eq('main~5')
      end
    end

    context 'when stdout has only one word (no symbolic name found)' do
      subject(:result) { described_instance.name_rev('deadbeef') }

      it 'returns nil' do
        allow(name_rev_command).to receive(:call).with('deadbeef').and_return(command_result("deadbeef\n"))
        expect(result).to be_nil
      end
    end

    context 'when commit_ish starts with a hyphen' do
      subject(:result) { described_instance.name_rev('--tags') }

      it 'raises ArgumentError before calling the command' do
        expect(Git::Commands::NameRev).not_to receive(:new)
        expect { result }.to raise_error(ArgumentError, "Invalid commit_ish: '--tags'")
      end
    end

    context 'when commit_ish is nil' do
      it 'does not raise ArgumentError' do
        allow(name_rev_command).to receive(:call).with(nil).and_return(command_result("undefined\n"))
        expect { described_instance.name_rev(nil) }.not_to raise_error
      end
    end
  end

  describe '#namerev' do
    it 'is an alias for #name_rev' do
      expect(described_class.instance_method(:namerev)).to eq(described_class.instance_method(:name_rev))
    end
  end

  describe '#ls_tree' do
    let(:ls_tree_command) { instance_double(Git::Commands::LsTree) }

    before do
      allow(Git::Commands::LsTree).to receive(:new)
        .with(execution_context)
        .and_return(ls_tree_command)
    end

    context 'with a sha and no options' do
      subject(:result) { described_instance.ls_tree('abc1234') }

      let(:ls_tree_output) do
        "100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tREADME.md\n" \
          "040000 tree abcdef0123456789abcdef0123456789abcdef01\tlib\n"
      end
      let(:ls_tree_result) { command_result(ls_tree_output) }
      let(:parsed_tree) do
        {
          'blob' => { 'README.md' => { mode: '100644', sha: 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391' } },
          'tree' => { 'lib' => { mode: '040000', sha: 'abcdef0123456789abcdef0123456789abcdef01' } },
          'commit' => {}
        }
      end

      before { allow(ls_tree_command).to receive(:call).and_return(ls_tree_result) }

      it 'constructs Git::Commands::LsTree with the execution context' do
        expect(Git::Commands::LsTree).to receive(:new).with(execution_context).and_return(ls_tree_command)
        allow(Git::Parsers::LsTree).to receive(:parse).and_return(parsed_tree)
        result
      end

      it 'calls Git::Commands::LsTree#call with the sha and no extra options' do
        expect(ls_tree_command).to receive(:call).with('abc1234').and_return(ls_tree_result)
        allow(Git::Parsers::LsTree).to receive(:parse).and_return(parsed_tree)
        result
      end

      it 'delegates to Git::Parsers::LsTree.parse with the stdout' do
        expect(Git::Parsers::LsTree).to receive(:parse).with(ls_tree_output).and_return(parsed_tree)
        result
      end

      it 'returns the value from Git::Parsers::LsTree.parse' do
        allow(Git::Parsers::LsTree).to receive(:parse).and_return(parsed_tree)
        expect(result).to eq(parsed_tree)
      end
    end

    context 'with recursive: true' do
      subject(:result) { described_instance.ls_tree('abc1234', recursive: true) }

      let(:ls_tree_result) { command_result("100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tlib/git.rb\n") }

      it 'calls Git::Commands::LsTree#call with r: true' do
        expect(ls_tree_command).to receive(:call).with('abc1234', r: true).and_return(ls_tree_result)
        result
      end
    end

    context 'with a path option' do
      subject(:result) { described_instance.ls_tree('abc1234', path: 'lib/') }

      let(:ls_tree_result) { command_result("040000 tree abcdef0123456789abcdef0123456789abcdef01\tlib\n") }

      it 'calls Git::Commands::LsTree#call with the path as a positional argument' do
        expect(ls_tree_command).to receive(:call).with('abc1234', 'lib/').and_return(ls_tree_result)
        result
      end
    end

    context 'with an array path option' do
      subject(:result) { described_instance.ls_tree('abc1234', path: %w[lib/ src/]) }

      let(:ls_tree_result) { command_result('') }

      it 'calls Git::Commands::LsTree#call with each path as a positional argument' do
        expect(ls_tree_command).to receive(:call).with('abc1234', 'lib/', 'src/').and_return(ls_tree_result)
        result
      end
    end

    context 'with an unsupported option' do
      it 'raises ArgumentError' do
        expect { described_instance.ls_tree('abc1234', bogus: true) }.to raise_error(ArgumentError)
      end
    end

    context 'when the tree is empty' do
      subject(:result) { described_instance.ls_tree('abc1234') }

      before { allow(ls_tree_command).to receive(:call).and_return(command_result('')) }

      it 'returns a Hash with empty sub-hashes for each object type' do
        expect(result).to eq({ 'blob' => {}, 'tree' => {}, 'commit' => {} })
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

    context 'when the archive command raises during staging' do
      before do
        allow(archive_command).to receive(:call).and_raise(RuntimeError, 'archive failed')
      end

      it 'cleans up the staging temp file and re-raises' do
        expect { described_instance.archive('HEAD') }.to raise_error(RuntimeError, /archive failed/)
      end
    end

    context 'when gzip post-processing raises an error' do
      before do
        allow(Zlib::GzipWriter).to receive(:open).and_raise(RuntimeError, 'gzip failed')
      end

      it 'cleans up temp files and re-raises' do
        expect { described_instance.archive('HEAD', nil, add_gzip: true) }.to raise_error(RuntimeError, /gzip failed/)
      end
    end

    context 'when atomically renaming the staging file to the destination fails' do
      let(:tmpfile) do
        t = Tempfile.new(['archive_unit', '.zip'])
        t.close
        t
      end

      after { tmpfile.close! }

      before do
        allow(File).to receive(:rename).and_raise(RuntimeError, 'rename failed')
      end

      it 'cleans up the staging file and re-raises' do
        expect { described_instance.archive('HEAD', tmpfile.path) }.to raise_error(RuntimeError, /rename failed/)
      end
    end

    context 'with an output path that does not yet exist' do
      let(:new_dest) { File.join(Dir.tmpdir, "archive_unit_new_#{Process.pid}.zip") }

      after { FileUtils.rm_f(new_dest) }

      it 'archives to the new destination path' do
        result = described_instance.archive('HEAD', new_dest)
        expect(result).to eq(new_dest)
      end
    end

    context 'when creating the staging temp file raises before assignment' do
      before do
        allow(Tempfile).to receive(:create).with('archive', anything)
                                           .and_raise(Errno::ENOSPC, 'No space left on device')
      end

      it 'propagates the error' do
        expect { described_instance.archive('HEAD') }.to raise_error(Errno::ENOSPC)
      end
    end

    context 'when creating the gzip temp file raises before assignment' do
      before do
        allow(Tempfile).to receive(:create).and_call_original
        allow(Tempfile).to receive(:create).with('archive_gz', anything)
                                           .and_raise(Errno::ENOSPC, 'No space left on device')
      end

      it 'propagates the error' do
        expect { described_instance.archive('HEAD', nil, add_gzip: true) }.to raise_error(Errno::ENOSPC)
      end
    end

    context 'when gzip raises and the staging file is not yet closed when rescue runs' do
      let(:staging_file_path) { File.join(Dir.tmpdir, "fake_archive_#{Process.pid}") }
      let(:staging_file) { instance_double(File, path: staging_file_path) }

      before do
        allow(staging_file).to receive(:binmode)
        allow(staging_file).to receive(:close)
        allow(staging_file).to receive(:closed?).and_return(false)
        allow(Tempfile).to receive(:create).and_call_original
        allow(Tempfile).to receive(:create).with('archive', anything).and_return(staging_file)
        allow(Zlib::GzipWriter).to receive(:open).and_raise(RuntimeError, 'gzip error')
      end

      it 'closes the staging file and re-raises' do
        expect { described_instance.archive('HEAD', nil, add_gzip: true) }.to raise_error(RuntimeError, /gzip error/)
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

      let(:nul) { "\0" }
      let(:grep_output) { "HEAD:src/foo.rb#{nul}12#{nul}# TODO: fix this\n" }
      let(:grep_result) { command_result(grep_output) }

      it 'constructs Git::Commands::Grep with the execution context' do
        expect(Git::Commands::Grep).to receive(:new).with(execution_context).and_return(grep_command)
        allow(grep_command).to receive(:call).and_return(grep_result)
        result
      end

      it 'calls Git::Commands::Grep#call with HEAD, the pattern, no_color, and line_number' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', no_color: true, line_number: true, null: true)
          .and_return(grep_result)
        result
      end

      it 'delegates to Git::Parsers::Grep.parse with the raw output' do
        allow(grep_command).to receive(:call).and_return(grep_result)
        expect(Git::Parsers::Grep).to receive(:parse)
          .with(grep_output)
          .and_return('HEAD:src/foo.rb' => [[12, '# TODO: fix this']])
        result
      end

      it 'returns the value from Git::Parsers::Grep.parse' do
        allow(grep_command).to receive(:call).and_return(grep_result)
        parsed = { 'HEAD:src/foo.rb' => [[12, '# TODO: fix this']] }
        allow(Git::Parsers::Grep).to receive(:parse).and_return(parsed)
        expect(result).to eq(parsed)
      end
    end

    context 'with a path_limiter String' do
      subject(:result) { described_instance.grep('TODO', 'src/') }

      it 'forwards pathspec as an Array to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', pathspec: ['src/'], no_color: true, line_number: true, null: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with a path_limiter Array' do
      subject(:result) { described_instance.grep('TODO', ['src/', 'lib/']) }

      it 'forwards pathspec as the same Array to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', pathspec: ['src/', 'lib/'], no_color: true, line_number: true, null: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with an :object option' do
      subject(:result) { described_instance.grep('TODO', nil, object: 'abc1234') }

      it 'uses the given object instead of HEAD' do
        expect(grep_command).to receive(:call)
          .with('abc1234', pattern: 'TODO', no_color: true, line_number: true, null: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :ignore_case option' do
      subject(:result) { described_instance.grep('todo', nil, ignore_case: true) }

      it 'forwards ignore_case to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'todo', ignore_case: true, no_color: true, line_number: true, null: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :i alias' do
      subject(:result) { described_instance.grep('todo', nil, i: true) }

      it 'forwards :i to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'todo', i: true, no_color: true, line_number: true, null: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :invert_match option' do
      subject(:result) { described_instance.grep('TODO', nil, invert_match: true) }

      it 'forwards invert_match to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'TODO', invert_match: true, no_color: true, line_number: true, null: true)
          .and_return(command_result(''))
        result
      end
    end

    context 'with :extended_regexp option' do
      subject(:result) { described_instance.grep('foo|bar', nil, extended_regexp: true) }

      it 'forwards extended_regexp to the command' do
        expect(grep_command).to receive(:call)
          .with('HEAD', pattern: 'foo|bar', extended_regexp: true, no_color: true, line_number: true, null: true)
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

  describe '#gblob' do
    subject(:result) { described_instance.gblob('HEAD:README.md') }

    let(:blob_object) { instance_double(Git::Object::Blob) }

    it 'delegates to Git::Object.new with the repository as base and type blob' do
      expect(Git::Object).to receive(:new)
        .with(described_instance, 'HEAD:README.md', 'blob')
        .and_return(blob_object)
      expect(result).to be(blob_object)
    end
  end

  describe '#gcommit' do
    subject(:result) { described_instance.gcommit('HEAD') }

    let(:commit_object) { instance_double(Git::Object::Commit) }

    it 'delegates to Git::Object.new with the repository as base and type commit' do
      expect(Git::Object).to receive(:new)
        .with(described_instance, 'HEAD', 'commit')
        .and_return(commit_object)
      expect(result).to be(commit_object)
    end
  end

  describe '#gtree' do
    subject(:result) { described_instance.gtree('HEAD^{tree}') }

    let(:tree_object) { instance_double(Git::Object::Tree) }

    it 'delegates to Git::Object.new with the repository as base and type tree' do
      expect(Git::Object).to receive(:new)
        .with(described_instance, 'HEAD^{tree}', 'tree')
        .and_return(tree_object)
      expect(result).to be(tree_object)
    end
  end

  describe '#tag' do
    subject(:result) { described_instance.tag('v1.0') }

    let(:tag_object) { instance_double(Git::Object::Tag) }

    it 'delegates to Git::Object::Tag.new with the repository as base' do
      expect(Git::Object::Tag).to receive(:new)
        .with(described_instance, 'v1.0')
        .and_return(tag_object)
      expect(result).to be(tag_object)
    end
  end

  describe '#object' do
    subject(:result) { described_instance.object('HEAD') }

    let(:commit_object) { instance_double(Git::Object::Commit) }

    it 'delegates to Git::Object.new with the repository as base and no type hint' do
      expect(Git::Object).to receive(:new)
        .with(described_instance, 'HEAD')
        .and_return(commit_object)
      expect(result).to be(commit_object)
    end
  end

  describe '#tags' do
    subject(:result) { described_instance.tags }

    let(:list_command) { instance_double(Git::Commands::Tag::List) }
    let(:command_result) { instance_double(Git::CommandLineResult, stdout: 'raw-stdout') }
    let(:tag_first) { instance_double(Git::Object::Tag) }
    let(:tag_second) { instance_double(Git::Object::Tag) }

    before do
      allow(Git::Commands::Tag::List).to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command).to receive(:call).and_return(command_result)
      allow(Git::Parsers::Tag).to receive(:parse_list).with('raw-stdout').and_return(
        [instance_double(Git::TagInfo, name: 'v1.0.0'), instance_double(Git::TagInfo, name: 'v2.0.0')]
      )
      allow(described_instance).to receive(:tag).with('v1.0.0').and_return(tag_first)
      allow(described_instance).to receive(:tag).with('v2.0.0').and_return(tag_second)
    end

    it 'constructs Git::Commands::Tag::List with the execution context' do
      expect(Git::Commands::Tag::List).to receive(:new).with(execution_context).and_return(list_command)
      result
    end

    it 'requests the parser format string from the list command' do
      expect(list_command).to receive(:call).with(format: Git::Parsers::Tag::FORMAT_STRING).and_return(command_result)
      result
    end

    it 'parses the command stdout with Git::Parsers::Tag' do
      expect(Git::Parsers::Tag).to receive(:parse_list).with('raw-stdout').and_return([])
      result
    end

    it 'returns one Git::Object::Tag per parsed tag name' do
      expect(result).to eq([tag_first, tag_second])
    end

    context 'when there are no tags' do
      before do
        allow(Git::Parsers::Tag).to receive(:parse_list).with('raw-stdout').and_return([])
      end

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end
  end

  describe '#tag_add' do
    let(:create_command) { instance_double(Git::Commands::Tag::Create) }
    let(:command_result) { instance_double(Git::CommandLineResult) }
    let(:tag_object) { instance_double(Git::Object::Tag) }

    before do
      allow(Git::Commands::Tag::Create).to receive(:new).with(execution_context).and_return(create_command)
      allow(create_command).to receive(:call).and_return(command_result)
      allow(described_instance).to receive(:tag).with('v1.0.0').and_return(tag_object)
    end

    it 'constructs Git::Commands::Tag::Create with the execution context' do
      expect(Git::Commands::Tag::Create).to receive(:new).with(execution_context).and_return(create_command)
      described_instance.tag_add('v1.0.0')
    end

    it 'returns the Git::Object::Tag for the created tag' do
      expect(described_instance.tag_add('v1.0.0')).to be(tag_object)
    end

    context 'with no target and no options' do
      it 'calls the create command with a nil commit and no options' do
        expect(create_command).to receive(:call).with('v1.0.0', nil).and_return(command_result)
        described_instance.tag_add('v1.0.0')
      end
    end

    context 'with a target commit' do
      it 'forwards the target as the commit operand' do
        expect(create_command).to receive(:call).with('v1.0.0', 'abc123').and_return(command_result)
        described_instance.tag_add('v1.0.0', 'abc123')
      end
    end

    context 'with an options hash only' do
      it 'forwards the options and a nil commit' do
        expect(create_command).to receive(:call)
          .with('v1.0.0', nil, annotate: true, message: 'hi').and_return(command_result)
        described_instance.tag_add('v1.0.0', annotate: true, message: 'hi')
      end
    end

    context 'with both a target and an options hash' do
      it 'forwards the target and options' do
        expect(create_command).to receive(:call)
          .with('v1.0.0', 'abc123', force: true).and_return(command_result)
        described_instance.tag_add('v1.0.0', 'abc123', force: true)
      end
    end

    context 'with a positional options hash (legacy call shape)' do
      it 'accepts the trailing hash as options' do
        expect(create_command).to receive(:call)
          .with('v1.0.0', nil, force: true).and_return(command_result)
        described_instance.tag_add('v1.0.0', { force: true })
      end
    end

    context 'when an unknown option is provided' do
      it 'raises ArgumentError without calling git' do
        expect(Git::Commands::Tag::Create).not_to receive(:new)
        expect { described_instance.tag_add('v1.0.0', bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when an annotated tag is requested without a message' do
      it 'raises ArgumentError without calling git' do
        expect(Git::Commands::Tag::Create).not_to receive(:new)
        expect { described_instance.tag_add('v1.0.0', annotate: true) }
          .to raise_error(ArgumentError, 'Cannot create an annotated or signed tag without a message.')
      end
    end

    context 'when a signed tag is requested without a message' do
      it 'raises ArgumentError without calling git' do
        expect(Git::Commands::Tag::Create).not_to receive(:new)
        expect { described_instance.tag_add('v1.0.0', s: true) }
          .to raise_error(ArgumentError, 'Cannot create an annotated or signed tag without a message.')
      end
    end

    context 'when an annotated tag is requested with a message' do
      it 'creates the tag and returns it' do
        expect(described_instance.tag_add('v1.0.0', annotate: true, message: 'release')).to be(tag_object)
      end
    end

    context 'when an annotated tag is requested with a :file option' do
      it 'does not raise and creates the tag' do
        expect(described_instance.tag_add('v1.0.0', annotate: true, file: 'msg.txt')).to be(tag_object)
      end
    end

    context 'when an annotated tag is requested with the :F alias' do
      it 'does not raise and creates the tag' do
        expect(described_instance.tag_add('v1.0.0', annotate: true, F: 'msg.txt')).to be(tag_object)
      end
    end

    context 'when a signed tag is requested with a :file option' do
      it 'does not raise and creates the tag' do
        expect(described_instance.tag_add('v1.0.0', sign: true, file: 'msg.txt')).to be(tag_object)
      end
    end

    context 'when a signed tag is requested with the :F alias' do
      it 'does not raise and creates the tag' do
        expect(described_instance.tag_add('v1.0.0', sign: true, F: 'msg.txt')).to be(tag_object)
      end
    end

    context 'when the deprecated :d option is given' do
      let(:delete_stdout) { "Deleted tag 'v1.0.0' (was abc123)\n" }

      before do
        allow(described_instance).to receive(:tag_delete).with('v1.0.0').and_return(delete_stdout)
        allow(Git::Deprecation).to receive(:warn)
      end

      it 'issues a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).with(/deprecated/)
        described_instance.tag_add('v1.0.0', d: true)
      end

      it 'delegates to tag_delete and returns its stdout' do
        expect(described_instance).to receive(:tag_delete).with('v1.0.0').and_return(delete_stdout)
        expect(described_instance.tag_add('v1.0.0', d: true)).to eq(delete_stdout)
      end

      it 'does not call Git::Commands::Tag::Create' do
        expect(Git::Commands::Tag::Create).not_to receive(:new)
        described_instance.tag_add('v1.0.0', d: true)
      end

      it 'also accepts the :delete alias' do
        expect(described_instance).to receive(:tag_delete).with('v1.0.0').and_return(delete_stdout)
        described_instance.tag_add('v1.0.0', delete: true)
      end

      it 'raises ArgumentError when a target is also given' do
        expect { described_instance.tag_add('v1.0.0', 'abc123', d: true) }
          .to raise_error(ArgumentError, /target/)
      end

      it 'raises ArgumentError when other options are also given' do
        expect { described_instance.tag_add('v1.0.0', d: true, force: true) }
          .to raise_error(ArgumentError, /force/)
      end
    end

    context 'when :d is given as false' do
      it 'treats it as omitted and creates the tag normally' do
        expect(described_instance.tag_add('v1.0.0', d: false)).to be(tag_object)
      end
    end

    context 'when :delete is given as false' do
      it 'treats it as omitted and creates the tag normally' do
        expect(described_instance.tag_add('v1.0.0', delete: false)).to be(tag_object)
      end
    end

    context 'when :d is given as nil' do
      it 'treats it as omitted and creates the tag normally' do
        expect(described_instance.tag_add('v1.0.0', d: nil)).to be(tag_object)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #add_tag (deprecated alias for #tag_add)
  # ---------------------------------------------------------------------------

  describe '#add_tag' do
    let(:tag_object) { instance_double(Git::Object::Tag) }

    before do
      allow(described_instance).to receive(:tag_add).and_return(tag_object)
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning matching /add_tag is deprecated/' do
      expect(Git::Deprecation).to receive(:warn).with(/add_tag is deprecated/)
      described_instance.add_tag('v1.0.0')
    end

    it 'calls tag_add with all arguments forwarded and returns its return value' do
      expect(described_instance)
        .to receive(:tag_add).with('v1.0.0', 'abc123', { force: true })
        .and_return(tag_object)
      result = described_instance.add_tag('v1.0.0', 'abc123', force: true)
      expect(result).to be(tag_object)
    end
  end

  describe '#tag_delete' do
    subject(:result) { described_instance.tag_delete('v1.0.0') }

    let(:delete_command) { instance_double(Git::Commands::Tag::Delete) }
    let(:status) { instance_double(Process::Status, exitstatus: 0) }
    let(:command_result) do
      instance_double(
        Git::CommandLineResult,
        stdout: "Deleted tag 'v1.0.0' (was abc123)\n", stderr: '', status: status,
        git_cmd: %w[git tag --delete v1.0.0]
      )
    end

    before do
      allow(Git::Commands::Tag::Delete).to receive(:new).with(execution_context).and_return(delete_command)
      allow(delete_command).to receive(:call).with('v1.0.0').and_return(command_result)
    end

    it 'constructs Git::Commands::Tag::Delete with the execution context' do
      expect(Git::Commands::Tag::Delete).to receive(:new).with(execution_context).and_return(delete_command)
      result
    end

    it 'calls the delete command with the tag name' do
      expect(delete_command).to receive(:call).with('v1.0.0').and_return(command_result)
      result
    end

    it 'returns the command stdout' do
      expect(result).to eq("Deleted tag 'v1.0.0' (was abc123)\n")
    end

    context 'when the tag does not exist (exit status 1)' do
      let(:status) { instance_double(Process::Status, exitstatus: 1) }

      it 'raises Git::FailedError carrying the failed command result' do
        expect { result }.to raise_error(Git::FailedError, /--delete/) do |error|
          expect(error.result).to be(command_result)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #delete_tag (deprecated alias for #tag_delete)
  # ---------------------------------------------------------------------------

  describe '#delete_tag' do
    let(:delete_stdout) { "Deleted tag 'v1.0.0' (was abc123)\n" }

    before do
      allow(described_instance).to receive(:tag_delete).and_return(delete_stdout)
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning matching /delete_tag is deprecated/' do
      expect(Git::Deprecation).to receive(:warn).with(/delete_tag is deprecated/)
      described_instance.delete_tag('v1.0.0')
    end

    it 'calls tag_delete with all arguments forwarded and returns its return value' do
      expect(described_instance)
        .to receive(:tag_delete).with('v1.0.0')
        .and_return(delete_stdout)
      result = described_instance.delete_tag('v1.0.0')
      expect(result).to be(delete_stdout)
    end
  end
end
