# frozen_string_literal: true

require 'spec_helper'
require 'git/object'

# These specs cover Git::Object::* classes.
# Full integration is covered by tests/units/test_object.rb (Test::Unit).

RSpec.describe Git::Object::Blob do
  # Git::Object::Blob is the concrete subclass used to exercise all
  # Git::Object::AbstractObject instance methods.

  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:repository) { Git::Repository.new(execution_context: execution_context) }
  let(:objectish) { 'abc123def456' }
  let(:described_instance) { described_class.new(repository, objectish) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores the objectish and defaults mode to nil' do
      expect(instance).to have_attributes(objectish: objectish, mode: nil)
    end

    context 'with a mode argument' do
      let(:described_instance) { described_class.new(repository, objectish, '100644') }

      it 'stores the provided mode' do
        expect(instance).to have_attributes(objectish: objectish, mode: '100644')
      end
    end
  end

  describe '#sha' do
    subject(:result) { described_instance.sha }

    let(:full_sha) { 'abc123def456full0000000000000000000000000' }

    before do
      allow(repository).to receive(:rev_parse).with(objectish).and_return(full_sha)
    end

    it 'resolves the objectish to a full SHA via the repository' do
      expect(result).to eq(full_sha)
    end

    it 'caches the result on subsequent calls' do
      2.times { described_instance.sha }
      expect(repository).to have_received(:rev_parse).once
    end
  end

  describe '#size' do
    subject(:result) { described_instance.size }

    before do
      allow(repository).to receive(:cat_file_size).with(objectish).and_return(42)
    end

    it 'returns the object size in bytes from the repository' do
      expect(result).to eq(42)
    end
  end

  describe '#contents' do
    context 'without a block' do
      subject(:result) { described_instance.contents }

      before do
        allow(repository).to receive(:cat_file_contents).with(objectish).and_return("file content\n")
      end

      it 'returns the raw content string from the repository' do
        expect(result).to eq("file content\n")
      end

      it 'caches the result on subsequent calls' do
        2.times { described_instance.contents }
        expect(repository).to have_received(:cat_file_contents).once
      end
    end

    context 'with a block' do
      subject(:result) { described_instance.contents { |f| f } }

      let(:file_double) { instance_double(File) }

      before do
        allow(repository).to receive(:cat_file_contents).with(objectish) do |_obj, &blk|
          blk.call(file_double)
        end
      end

      it 'yields the streamed file to the block and returns the block value' do
        expect(result).to be(file_double)
      end
    end
  end

  describe '#grep' do
    subject(:result) { described_instance.grep('TODO', 'lib/', ignore_case: true) }

    let(:grep_result) { { 'lib/foo.rb' => { 42 => 'TODO: fix this' } } }

    before do
      allow(repository).to receive(:rev_parse).with(objectish).and_return(objectish)
      allow(repository).to receive(:grep)
        .with('TODO', 'lib/', hash_including(object: objectish, ignore_case: true))
        .and_return(grep_result)
    end

    it 'delegates to the repository with the object SHA and path limiter' do
      expect(result).to eq(grep_result)
    end
  end

  describe '#archive' do
    subject(:result) { described_instance.archive('/tmp/out.zip', format: 'zip') }

    before do
      allow(repository).to receive(:archive)
        .with(objectish, '/tmp/out.zip', { format: 'zip' })
        .and_return('/tmp/out.zip')
    end

    it 'delegates to the repository with the objectish, destination, and options' do
      expect(result).to eq('/tmp/out.zip')
    end
  end

  describe '#blob?' do
    subject(:result) { described_instance.blob? }

    it 'returns true' do
      expect(result).to be(true)
    end
  end

  describe '#contents_array' do
    subject(:result) { described_instance.contents_array }

    before do
      allow(repository).to receive(:cat_file_contents).with(objectish).and_return("line1\nline2\nline3")
    end

    it 'returns the object content split into individual lines' do
      expect(result).to eq(%w[line1 line2 line3])
    end
  end

  describe '#diff' do
    subject(:result) { described_instance.diff('HEAD') }

    it 'returns a Git::Diff from this objectish to the given objectish' do
      expect(result).to be_a(Git::Diff)
      expect(result.from).to eq(objectish)
      expect(result.to).to eq('HEAD')
    end
  end

  describe '#log' do
    subject(:result) { described_instance.log(10) }

    it 'returns a Git::Log instance' do
      expect(result).to be_a(Git::Log)
    end
  end

  describe '#to_s' do
    subject(:result) { described_instance.to_s }

    it 'returns the objectish string' do
      expect(result).to eq(objectish)
    end
  end

  describe '#tree?' do
    subject(:result) { described_instance.tree? }

    it 'returns false' do
      expect(result).to be(false)
    end
  end

  describe '#commit?' do
    subject(:result) { described_instance.commit? }

    it 'returns false' do
      expect(result).to be(false)
    end
  end

  describe '#tag?' do
    subject(:result) { described_instance.tag? }

    it 'returns false' do
      expect(result).to be(false)
    end
  end
end

RSpec.describe Git::Object::Tree do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:repository) { Git::Repository.new(execution_context: execution_context) }
  let(:tree_sha) { 'treeshaabc123' }
  let(:described_instance) { described_class.new(repository, tree_sha) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores the objectish and defaults mode to nil' do
      expect(instance).to have_attributes(objectish: tree_sha, mode: nil)
    end

    context 'with a mode argument' do
      let(:described_instance) { described_class.new(repository, tree_sha, '040000') }

      it 'stores the provided mode' do
        expect(instance).to have_attributes(objectish: tree_sha, mode: '040000')
      end
    end
  end

  describe '#full_tree' do
    subject(:result) { described_instance.full_tree }

    let(:entries) do
      [
        "100644 blob e69de29\tlib/git.rb",
        "100644 blob abc1234\tREADME.md"
      ]
    end

    before do
      allow(repository).to receive(:full_tree).with(tree_sha).and_return(entries)
    end

    it 'returns the recursive tree entries from the repository' do
      expect(result).to eq(entries)
    end
  end

  describe '#depth' do
    subject(:result) { described_instance.depth }

    before do
      allow(repository).to receive(:tree_depth).with(tree_sha).and_return(3)
    end

    it 'returns the tree depth from the repository' do
      expect(result).to eq(3)
    end
  end

  describe '#blobs' do
    subject(:result) { described_instance.blobs }

    let(:ls_tree_data) do
      {
        'tree' => {},
        'blob' => { 'README.md' => { sha: 'blobsha123', mode: '100644' } }
      }
    end

    before do
      allow(repository).to receive(:ls_tree).with(tree_sha).and_return(ls_tree_data)
    end

    it 'returns a hash of Blob objects keyed by path' do
      expect(result).to include('README.md' => an_instance_of(Git::Object::Blob))
    end
  end

  describe '#files' do
    subject(:result) { described_instance.files }

    let(:ls_tree_data) do
      {
        'tree' => {},
        'blob' => { 'README.md' => { sha: 'blobsha123', mode: '100644' } }
      }
    end

    before do
      allow(repository).to receive(:ls_tree).with(tree_sha).and_return(ls_tree_data)
    end

    it 'returns a hash of Blob objects keyed by path' do
      expect(result).to include('README.md' => an_instance_of(Git::Object::Blob))
    end
  end

  describe '#trees' do
    subject(:result) { described_instance.trees }

    let(:ls_tree_data) do
      {
        'tree' => { 'lib' => { sha: 'libsha456', mode: '040000' } },
        'blob' => {}
      }
    end

    before do
      allow(repository).to receive(:ls_tree).with(tree_sha).and_return(ls_tree_data)
    end

    it 'returns a hash of sub-Tree objects keyed by path' do
      expect(result).to include('lib' => an_instance_of(Git::Object::Tree))
    end
  end

  describe '#subtrees' do
    subject(:result) { described_instance.subtrees }

    let(:ls_tree_data) do
      {
        'tree' => { 'lib' => { sha: 'libsha456', mode: '040000' } },
        'blob' => {}
      }
    end

    before do
      allow(repository).to receive(:ls_tree).with(tree_sha).and_return(ls_tree_data)
    end

    it 'returns a hash of sub-Tree objects keyed by path' do
      expect(result).to include('lib' => an_instance_of(Git::Object::Tree))
    end
  end

  describe '#subdirectories' do
    subject(:result) { described_instance.subdirectories }

    let(:ls_tree_data) do
      {
        'tree' => { 'lib' => { sha: 'libsha456', mode: '040000' } },
        'blob' => {}
      }
    end

    before do
      allow(repository).to receive(:ls_tree).with(tree_sha).and_return(ls_tree_data)
    end

    it 'returns a hash of sub-Tree objects keyed by path' do
      expect(result).to include('lib' => an_instance_of(Git::Object::Tree))
    end
  end

  describe '#tree?' do
    subject(:result) { described_instance.tree? }

    it 'returns true' do
      expect(result).to be(true)
    end
  end

  describe '#children' do
    subject(:result) { described_instance.children }

    let(:ls_tree_data) do
      {
        'tree' => { 'lib' => { sha: 'libsha456', mode: '040000' } },
        'blob' => { 'README.md' => { sha: 'blobsha123', mode: '100644' } }
      }
    end

    before do
      allow(repository).to receive(:ls_tree).with(tree_sha).and_return(ls_tree_data)
    end

    it 'returns a merged hash of all blobs and sub-trees keyed by path' do
      expect(result).to include(
        'README.md' => an_instance_of(Git::Object::Blob),
        'lib' => an_instance_of(Git::Object::Tree)
      )
    end
  end
end

RSpec.describe Git::Object::Commit do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:repository) { Git::Repository.new(execution_context: execution_context) }
  let(:commit_sha) { 'commitsha123abc' }
  let(:described_instance) { described_class.new(repository, commit_sha) }

  let(:commit_data) do
    {
      'sha' => commit_sha,
      'tree' => 'treesha456def',
      'parent' => ['parentsha789ghi'],
      'author' => 'A U Thor <author@example.com> 1234567890 +0000',
      'committer' => 'A U Thor <author@example.com> 1234567890 +0000',
      'message' => "Initial commit\n"
    }
  end

  before do
    allow(repository).to receive(:cat_file_commit).with(commit_sha).and_return(commit_data)
  end

  describe '#initialize' do
    subject(:commit) { described_class.new(repository, commit_sha, init) }

    let(:init) { nil }

    context 'without init data (lazy loading)' do
      it 'stores the objectish without eagerly loading commit data' do
        commit
        expect(repository).not_to have_received(:cat_file_commit)
      end
    end

    context 'when init data is provided' do
      let(:init) { commit_data }

      it 'populates commit attributes immediately without calling cat_file_commit' do
        expect(repository).not_to receive(:cat_file_commit)
        expect(commit.message).to eq('Initial commit')
      end
    end
  end

  describe '#from_data' do
    it 'populates all commit attributes from the data hash' do
      described_instance.from_data(commit_data)
      expect(described_instance.message).to eq('Initial commit')
      expect(described_instance.author).to have_attributes(
        name: 'A U Thor', email: 'author@example.com'
      )
      expect(described_instance.gtree.objectish).to eq('treesha456def')
      expect(described_instance.parents.first.objectish).to eq('parentsha789ghi')
    end
  end

  describe '#message' do
    subject(:result) { described_instance.message }

    it 'returns the commit message with trailing newline stripped' do
      expect(result).to eq('Initial commit')
    end
  end

  describe '#gtree' do
    subject(:result) { described_instance.gtree }

    it 'returns a Tree object for the commit tree SHA' do
      expect(result).to be_a(Git::Object::Tree)
      expect(result.objectish).to eq('treesha456def')
    end
  end

  describe '#parents' do
    subject(:result) { described_instance.parents }

    it 'returns an array of Commit objects for the parent SHAs' do
      expect(result).to contain_exactly(an_instance_of(Git::Object::Commit))
      expect(result.first.objectish).to eq('parentsha789ghi')
    end
  end

  describe '#name' do
    subject(:result) { described_instance.name }

    before do
      allow(repository).to receive(:rev_parse).with(commit_sha).and_return(commit_sha)
      allow(repository).to receive(:name_rev).with(commit_sha).and_return('main~3')
    end

    it 'returns a human-readable name for the commit via the repository' do
      expect(result).to eq('main~3')
    end
  end

  describe '#parent' do
    subject(:result) { described_instance.parent }

    it 'returns the first parent commit' do
      expect(result).to be_a(Git::Object::Commit)
      expect(result.objectish).to eq('parentsha789ghi')
    end
  end

  describe '#author' do
    subject(:result) { described_instance.author }

    it 'returns the commit author with correct name and email' do
      expect(result).to have_attributes(name: 'A U Thor', email: 'author@example.com')
    end
  end

  describe '#author_date' do
    subject(:result) { described_instance.author_date }

    it 'returns the author timestamp' do
      expect(result).to eq(Time.at(1_234_567_890))
    end
  end

  describe '#committer' do
    subject(:result) { described_instance.committer }

    it 'returns the committer with correct name and email' do
      expect(result).to have_attributes(name: 'A U Thor', email: 'author@example.com')
    end
  end

  describe '#committer_date' do
    subject(:result) { described_instance.committer_date }

    it 'returns the committer timestamp' do
      expect(result).to eq(Time.at(1_234_567_890))
    end
  end

  describe '#date' do
    subject(:result) { described_instance.date }

    it 'returns the committer timestamp' do
      expect(result).to eq(Time.at(1_234_567_890))
    end
  end

  describe '#diff_parent' do
    subject(:result) { described_instance.diff_parent }

    it 'returns a Git::Diff from this commit to its first parent' do
      expect(result).to be_a(Git::Diff)
      expect(result.from).to eq(commit_sha)
      expect(result.to).to eq('parentsha789ghi')
    end
  end

  describe '#set_commit' do
    before do
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning' do
      described_instance.set_commit(commit_data)
      expect(Git::Deprecation).to have_received(:warn).with(a_string_including('deprecated'))
    end

    it 'populates the commit attributes from the given data hash' do
      described_instance.set_commit(commit_data)
      expect(described_instance.message).to eq('Initial commit')
    end
  end

  describe '#commit?' do
    subject(:result) { described_instance.commit? }

    it 'returns true' do
      expect(result).to be(true)
    end
  end
end

RSpec.describe Git::Object::Tag do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:repository) { Git::Repository.new(execution_context: execution_context) }
  let(:described_instance) { described_class.new(repository, 'tagsha123abc', 'v1.0') }

  describe '#initialize' do
    subject(:tag) { described_class.new(base, sha, name) }

    let(:base) { repository }
    let(:sha) { 'tagsha123abc' }
    let(:name) { 'v1.0' }

    context 'with name only (two-argument form)' do
      let(:sha) { 'v1.0' }
      let(:name) { nil }

      before do
        allow(repository).to receive(:tag_sha).with('v1.0').and_return('tagsha123abc')
      end

      it 'resolves the SHA via the repository and stores the name' do
        expect(tag.objectish).to eq('tagsha123abc')
        expect(tag.name).to eq('v1.0')
      end
    end

    context 'when the tag does not exist' do
      let(:sha) { 'nonexistent' }
      let(:name) { nil }

      before do
        allow(repository).to receive(:tag_sha).with('nonexistent').and_return('')
      end

      it 'raises Git::UnexpectedResultError' do
        expect { tag }.to raise_error(Git::UnexpectedResultError, /nonexistent/)
      end
    end

    context 'with explicit sha and name (three-argument form)' do
      it 'does not call tag_sha on the repository' do
        expect(repository).not_to receive(:tag_sha)
        tag
      end

      it 'stores the SHA and name without a lookup' do
        expect(tag.objectish).to eq('tagsha123abc')
        expect(tag.name).to eq('v1.0')
      end
    end
  end

  describe '#annotated?' do
    subject(:result) { described_instance.annotated? }

    context 'when the tag object type is "tag" (annotated)' do
      before do
        allow(repository).to receive(:cat_file_type).with('v1.0').and_return('tag')
      end

      it 'returns true' do
        expect(result).to be(true)
      end
    end

    context 'when the tag object type is "commit" (lightweight)' do
      before do
        allow(repository).to receive(:cat_file_type).with('v1.0').and_return('commit')
      end

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context 'when called multiple times' do
      before do
        allow(repository).to receive(:cat_file_type).with('v1.0').and_return('tag')
      end

      it 'caches the result and does not call cat_file_type again' do
        2.times { described_instance.annotated? }
        expect(repository).to have_received(:cat_file_type).once
      end
    end
  end

  describe '#message' do
    subject(:result) { described_instance.message }

    context 'when the tag is annotated' do
      let(:tag_data) do
        {
          'name' => 'v1.0',
          'object' => 'commitsha',
          'type' => 'commit',
          'tag' => 'v1.0',
          'tagger' => 'A U Thor <author@example.com> 1234567890 +0000',
          'message' => "Release v1.0\n"
        }
      end

      before do
        allow(repository).to receive(:cat_file_type).with('v1.0').and_return('tag')
        allow(repository).to receive(:cat_file_tag).with('v1.0').and_return(tag_data)
      end

      it 'returns the tag message with trailing newline stripped' do
        expect(result).to eq('Release v1.0')
      end
    end

    context 'when the tag is lightweight (not annotated)' do
      before do
        allow(repository).to receive(:cat_file_type).with('v1.0').and_return('commit')
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when called multiple times (annotated)' do
      let(:tag_data) do
        {
          'name' => 'v1.0',
          'object' => 'commitsha',
          'type' => 'commit',
          'tag' => 'v1.0',
          'tagger' => 'A U Thor <author@example.com> 1234567890 +0000',
          'message' => "Release v1.0\n"
        }
      end

      before do
        allow(repository).to receive(:cat_file_type).with('v1.0').and_return('tag')
        allow(repository).to receive(:cat_file_tag).with('v1.0').and_return(tag_data)
      end

      it 'caches the tag data and does not re-fetch from repository' do
        2.times { described_instance.message }
        expect(repository).to have_received(:cat_file_tag).once
      end
    end
  end

  describe '#tag?' do
    subject(:result) { described_instance.tag? }

    it 'returns true' do
      expect(result).to be(true)
    end
  end

  describe '#tagger' do
    subject(:result) { described_instance.tagger }

    context 'when the tag is annotated' do
      let(:tag_data) do
        {
          'name' => 'v1.0',
          'object' => 'commitsha',
          'type' => 'commit',
          'tag' => 'v1.0',
          'tagger' => 'A U Thor <author@example.com> 1234567890 +0000',
          'message' => "Release v1.0\n"
        }
      end

      before do
        allow(repository).to receive(:cat_file_type).with('v1.0').and_return('tag')
        allow(repository).to receive(:cat_file_tag).with('v1.0').and_return(tag_data)
      end

      it 'returns the tag creator with correct name and email' do
        expect(result).to have_attributes(name: 'A U Thor', email: 'author@example.com')
      end
    end
  end
end

RSpec.describe Git::Object do
  describe '.new' do
    let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
    let(:repository) { Git::Repository.new(execution_context: execution_context) }

    context 'when type is provided' do
      context 'with type "commit"' do
        subject(:result) { described_class.new(repository, 'HEAD', 'commit') }

        it 'creates a Commit without calling cat_file_type' do
          expect(repository).not_to receive(:cat_file_type)
          expect(result).to be_a(Git::Object::Commit)
        end
      end

      context 'with type "blob"' do
        subject(:result) { described_class.new(repository, 'HEAD:file.txt', 'blob') }

        it 'creates a Blob' do
          expect(result).to be_a(Git::Object::Blob)
        end
      end

      context 'with type "tree"' do
        subject(:result) { described_class.new(repository, 'HEAD^{tree}', 'tree') }

        it 'creates a Tree' do
          expect(result).to be_a(Git::Object::Tree)
        end
      end
    end

    context 'when type is not provided' do
      subject(:result) { described_class.new(repository, 'HEAD') }

      before do
        allow(repository).to receive(:cat_file_type).with('HEAD').and_return('commit')
      end

      it 'calls cat_file_type on the repository to determine the object type' do
        expect(result).to be_a(Git::Object::Commit)
      end
    end

    context 'when is_tag is true (deprecated form)' do
      before do
        allow(repository).to receive(:tag_sha).with('v1.0').and_return('tagsha123abc')
        allow(Git::Deprecation).to receive(:warn)
      end

      it 'creates a Tag via the deprecated new_tag path and emits a deprecation warning' do
        result = described_class.new(repository, 'v1.0', nil, true)
        expect(result).to be_a(Git::Object::Tag)
        expect(Git::Deprecation).to have_received(:warn).with(a_string_including('deprecated'))
      end
    end

    context 'when type does not match any known object type' do
      it 'raises NoMethodError due to nil class' do
        expect { described_class.new(repository, 'abc123', 'unknown') }
          .to raise_error(NoMethodError, /undefined method [`']new[`'].*nil/)
      end
    end
  end
end
