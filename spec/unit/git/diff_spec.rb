# frozen_string_literal: true

require 'spec_helper'
require 'git/diff'
require 'git/object'
require 'git/repository'

RSpec.describe Git::Diff do
  let(:patch_text) do
    "diff --git a/lib/foo.rb b/lib/foo.rb\n--- a/lib/foo.rb\n+++ b/lib/foo.rb\n@@ -1 +1 @@\n-old\n+new\n"
  end

  let(:stats_hash) do
    {
      total: { files: 3, lines: 74, insertions: 64, deletions: 10 },
      files: { 'scott/newfile' => { insertions: 0, deletions: 1 } }
    }
  end

  let(:repository_base) { instance_double(Git::Repository) }

  before do
    allow(repository_base).to receive(:diff_full).and_return(patch_text)
    allow(repository_base).to receive(:diff_numstat).and_return(stats_hash)
  end

  let(:described_instance) { described_class.new(repository_base, 'HEAD~1', 'HEAD') }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments as readable attributes' do
      expect(instance).to have_attributes(from: 'HEAD~1', to: 'HEAD')
    end

    context 'when from and to are nil (index-to-working-tree diff)' do
      subject(:instance) { described_class.new(repository_base, nil, nil) }

      it 'stores nil for both the from and to attributes' do
        expect(instance).to have_attributes(from: nil, to: nil)
      end
    end

    context 'when passed a Git object as the to argument' do
      # Plain double: any object responding to to_s is a valid Git object ref
      let(:tree_object) { double('Git::Object::Tree', to_s: 'v2.5') }
      subject(:instance) { described_class.new(repository_base, 'HEAD~1', tree_object) }

      it 'converts the object to a string via to_s' do
        expect(instance.to).to eq('v2.5')
      end
    end
  end

  describe '#path' do
    subject(:result) { described_instance.path(*paths) }

    let(:paths) { [] }

    context 'when called with no arguments' do
      it 'returns self for chaining' do
        expect(result).to be(described_instance)
      end
    end

    context 'when called with a single path' do
      let(:paths) { ['lib/'] }

      it 'returns self for chaining' do
        expect(result).to be(described_instance)
      end

      it 'forwards the path to DiffStats as path_limiter' do
        expect(repository_base).to receive(:diff_numstat)
          .with('HEAD~1', 'HEAD', path_limiter: 'lib/')
          .and_return(total: { files: 2, lines: 9, insertions: 0, deletions: 9 }, files: {})
        result.size
      end
    end

    context 'when called with multiple paths' do
      let(:paths) { ['lib/', 'docs/'] }

      it 'returns self for chaining' do
        expect(result).to be(described_instance)
      end

      it 'forwards the paths array to DiffStats as path_limiter' do
        expect(repository_base).to receive(:diff_numstat)
          .with('HEAD~1', 'HEAD', path_limiter: %w[lib/ docs/])
          .and_return(total: { files: 3, lines: 74, insertions: 64, deletions: 10 }, files: {})
        result.size
      end
    end

    context 'when an Array is passed as an argument' do
      let(:paths) { [['lib/', 'docs/']] }

      it 'raises ArgumentError explaining splatted argument usage' do
        expect { result }.to raise_error(ArgumentError, /path expects individual arguments/)
      end
    end
  end

  describe '#patch' do
    subject(:result) { described_class.new(repository_base, 'HEAD~1', 'HEAD').patch }

    it 'calls diff_full with from, to, and path_limiter: nil' do
      expect(repository_base).to receive(:diff_full)
        .with('HEAD~1', 'HEAD', path_limiter: nil)
        .and_return(patch_text)
      result
    end

    it 'returns the patch text' do
      expect(result).to eq(patch_text)
    end

    context 'when a path filter has been set' do
      it 'forwards the path to diff_full as path_limiter' do
        expect(repository_base).to receive(:diff_full)
          .with('HEAD~1', 'HEAD', path_limiter: 'lib/')
          .and_return(patch_text)
        described_class.new(repository_base, 'HEAD~1', 'HEAD').path('lib/').patch
      end
    end

    context 'when obj2 is nil' do
      it 'passes nil as the second positional argument to diff_full' do
        expect(repository_base).to receive(:diff_full)
          .with('HEAD', nil, path_limiter: nil)
          .and_return(patch_text)
        described_class.new(repository_base, 'HEAD', nil).patch
      end
    end
  end

  describe '#to_s' do
    subject(:result) { described_instance.to_s }

    it 'is an alias for patch' do
      expect(result).to eq(patch_text)
    end
  end

  describe '#size' do
    subject(:size) { described_instance.size }

    it 'returns the number of changed files from DiffStats' do
      expect(size).to eq(3)
    end
  end

  describe '#lines' do
    subject(:lines) { described_instance.lines }

    it 'returns the total number of changed lines from DiffStats' do
      expect(lines).to eq(74)
    end
  end

  describe '#insertions' do
    subject(:insertions) { described_instance.insertions }

    it 'returns the total number of inserted lines from DiffStats' do
      expect(insertions).to eq(64)
    end
  end

  describe '#deletions' do
    subject(:deletions) { described_instance.deletions }

    it 'returns the total number of deleted lines from DiffStats' do
      expect(deletions).to eq(10)
    end
  end

  describe '#stats' do
    subject(:stats) { described_instance.stats }

    it 'returns total and per-file statistics in the expected structure' do
      expect(stats).to eq(
        files: { 'scott/newfile' => { insertions: 0, deletions: 1 } },
        total: { files: 3, lines: 74, insertions: 64, deletions: 10 }
      )
    end
  end

  describe '#each' do
    context 'when the diff contains patch-like content in a file' do
      let(:patch_text) do
        <<~DIFF.chomp
          diff --git a/my.patch b/my.patch
          new file mode 100644
          index 0000000..abc1234
          --- /dev/null
          +++ b/my.patch
          @@ -0,0 +1,3 @@
          +diff --git a/inner.rb b/inner.rb
          +index abc123..def456 100644
          +--- a/inner.rb
        DIFF
      end

      it 'does not split the diff on embedded patch-like content lines' do
        expect(described_instance.count).to eq(1)
      end
    end

    context 'when the patch starts with non-header content before the first diff line' do
      let(:patch_text) do
        "preamble line\ndiff --git a/foo.rb b/foo.rb\nindex abc..def 100644\n"
      end

      it 'ignores content before the first diff header' do
        expect(described_instance.count).to eq(1)
      end
    end

    context 'when a changed file is binary' do
      let(:patch_text) do
        <<~DIFF.chomp
          diff --git a/img.png b/img.png
          index abc1234..def5678 100644
          Binary files a/img.png and b/img.png differ
        DIFF
      end

      it 'marks the DiffFile as binary' do
        expect(described_instance.first.binary?).to be true
      end
    end

    context 'with a patch containing multiple changed files' do
      let(:patch_text) do
        <<~DIFF.chomp
          diff --git a/example.txt b/example.txt
          index 1f09f2e..8dc79ae 100644
          --- a/example.txt
          +++ b/example.txt
          @@ -1 +1 @@
          -old content
          +new content
          diff --git a/scott/newfile b/scott/newfile
          deleted file mode 100644
          index 5d46068..0000000
          --- a/scott/newfile
          +++ /dev/null
          @@ -1 +0,0 @@
          -content
        DIFF
      end

      it 'yields DiffFile objects with the expected attributes for each changed file' do
        files = described_instance.to_h { |f| [f.path, f] }

        expect(files['example.txt']).to be_a(Git::Diff::DiffFile)
        expect(files['scott/newfile']).to have_attributes(mode: '100644', type: 'deleted')
      end

      it 'is idempotent (parses the patch only once)' do
        expect(repository_base).to receive(:diff_full).once.and_return(patch_text)
        expect(described_instance.count).to eq(2)
        expect(described_instance.count).to eq(2)
      end
    end

    context 'when a changed file has a non-ASCII name that git quoted with octal escapes' do
      let(:patch_text) do
        # Git quotes non-ASCII filenames: \342\230\240 are the octal-escaped UTF-8
        # bytes for ☠ (U+2620). Using a single-quoted heredoc so backslashes are literal.
        <<~'DIFF'
          diff --git "a/my_other_file_\342\230\240" "b/my_other_file_\342\230\240"
          index abc1234..def5678 100644
          --- "a/my_other_file_\342\230\240"
          +++ "b/my_other_file_\342\230\240"
          @@ -1 +1 @@
          -First Line
          +Second Line
        DIFF
      end

      it 'unescapes the octal-encoded non-ASCII filename' do
        expect(described_instance.map(&:path)).to eq(['my_other_file_☠'])
      end
    end
  end

  describe '#[]' do
    subject(:diff_file) { described_instance['scott/newfile'] }

    let(:deletion_patch) do
      <<~DIFF.chomp
        diff --git a/scott/newfile b/scott/newfile
        deleted file mode 100644
        index #{src_sha}..#{dst_sha}
        --- a/scott/newfile
        +++ /dev/null
        @@ -1 +0,0 @@
        -content
      DIFF
    end

    let(:src_sha) { '5d46068' }
    let(:dst_sha) { '0000000' }

    before { allow(repository_base).to receive(:diff_full).and_return(deletion_patch) }

    it 'returns the DiffFile for the given path with parsed attributes' do
      expect(diff_file).to have_attributes(
        path: 'scott/newfile',
        src: '5d46068',
        dst: '0000000',
        type: 'deleted',
        mode: '100644'
      )
    end

    context 'when the index line uses minimum-length (4-character) abbreviated SHAs' do
      let(:src_sha) { '5d46' }
      let(:dst_sha) { '0000' }

      it 'parses the 4-character source SHA from the index line' do
        expect(diff_file.src).to eq('5d46')
      end
    end

    context 'when the index line uses full-length (40-character) SHAs' do
      let(:src_sha) { '5d4606820736043f9eed2a6336661d6892c820a5' }
      let(:dst_sha) { '0' * 40 }

      it 'parses the 40-character source SHA from the index line' do
        expect(diff_file.src).to eq('5d4606820736043f9eed2a6336661d6892c820a5')
      end
    end
  end
end

RSpec.describe Git::Diff::DiffFile do
  let(:repository_base) { instance_double(Git::Repository) }
  let(:blob_double) { instance_double(Git::Object::Blob) }

  let(:src_sha) { '5d46068' }
  let(:dst_sha) { '0000000' }

  let(:described_instance) do
    described_class.new(repository_base, {
                          patch: 'diff text', path: 'scott/newfile', mode: '100644',
                          src: src_sha, dst: dst_sha, type: 'deleted', binary: false
                        })
  end

  before do
    allow(repository_base).to receive(:object).with(src_sha).and_return(blob_double)
  end

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments as readable attributes' do
      expect(instance).to have_attributes(
        path: 'scott/newfile',
        mode: '100644',
        src: '5d46068',
        dst: '0000000',
        type: 'deleted'
      )
    end
  end

  describe '#binary?' do
    subject(:result) { described_instance.binary? }

    context 'when the file is not binary' do
      it { is_expected.to be false }
    end

    context 'when the file is binary' do
      let(:described_instance) do
        described_class.new(repository_base, {
                              patch: '', path: 'img.png', mode: '100644',
                              src: '0000000', dst: '0000000', type: 'modified', binary: true
                            })
      end

      it { is_expected.to be true }
    end
  end

  describe '#blob' do
    subject(:blob) { described_instance.blob(blob_kind) }

    let(:blob_kind) { :dst }

    context 'when type is :dst (default) and dst is a null SHA' do
      it 'returns nil' do
        expect(blob).to be_nil
      end
    end

    context 'when type is :dst (default) and dst is a 4-character null SHA' do
      let(:dst_sha) { '0000' }

      it 'returns nil because NIL_BLOB_REGEXP matches short null SHAs' do
        expect(blob).to be_nil
      end
    end

    context 'when type is :dst (default) and dst is not a null SHA' do
      let(:dst_sha) { 'abc1234' }

      before { allow(repository_base).to receive(:object).with('abc1234').and_return(blob_double) }

      it 'returns the blob object for the destination SHA' do
        expect(blob).to be(blob_double)
      end
    end

    context 'when type is :src and src is not a null SHA' do
      let(:blob_kind) { :src }

      it 'returns the blob object for the source SHA' do
        expect(blob).to be(blob_double)
      end
    end

    context 'when type is :src and src is a null SHA' do
      let(:blob_kind) { :src }
      let(:src_sha) { '0000000' }
      let(:dst_sha) { 'def4567' }

      before { allow(repository_base).to receive(:object).with('def4567').and_return(blob_double) }

      it 'returns nil rather than falling back to the destination blob' do
        expect(blob).to be_nil
      end
    end
  end
end
