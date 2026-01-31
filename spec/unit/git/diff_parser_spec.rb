# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_parser'

RSpec.describe Git::DiffParser do
  describe '.parse_shortstat' do
    it 'parses a complete shortstat line' do
      line = ' 3 files changed, 10 insertions(+), 5 deletions(-)'
      result = described_class.parse_shortstat(line)

      expect(result).to eq(files_changed: 3, insertions: 10, deletions: 5)
    end

    it 'parses with singular file' do
      line = ' 1 file changed, 2 insertions(+)'
      result = described_class.parse_shortstat(line)

      expect(result).to eq(files_changed: 1, insertions: 2, deletions: 0)
    end

    it 'parses deletions only' do
      line = ' 1 file changed, 3 deletions(-)'
      result = described_class.parse_shortstat(line)

      expect(result).to eq(files_changed: 1, insertions: 0, deletions: 3)
    end

    it 'returns zeros for nil input' do
      result = described_class.parse_shortstat(nil)

      expect(result).to eq(files_changed: 0, insertions: 0, deletions: 0)
    end
  end

  describe '.parse_dirstat' do
    it 'parses dirstat lines' do
      lines = [
        '  50.0% lib/',
        '  30.5% spec/',
        '  19.5% bin/'
      ]
      result = described_class.parse_dirstat(lines)

      expect(result).to be_a(Git::DirstatInfo)
      expect(result.entries.size).to eq(3)
      expect(result.entries[0].percentage).to eq(50.0)
      expect(result.entries[0].directory).to eq('lib/')
      expect(result.entries[1].percentage).to eq(30.5)
      expect(result.entries[2].directory).to eq('bin/')
    end

    it 'returns empty DirstatInfo for empty input' do
      result = described_class.parse_dirstat([])

      expect(result.entries).to be_empty
    end
  end

  describe '.parse_stat_value' do
    it 'parses numeric values' do
      expect(described_class.parse_stat_value('10')).to eq(10)
      expect(described_class.parse_stat_value('0')).to eq(0)
    end

    it 'returns 0 for binary marker' do
      expect(described_class.parse_stat_value('-')).to eq(0)
    end
  end

  describe '.unescape_path' do
    it 'returns unquoted paths unchanged' do
      expect(described_class.unescape_path('simple/path.rb')).to eq('simple/path.rb')
    end

    it 'unescapes quoted paths with spaces' do
      expect(described_class.unescape_path('"path/with spaces.rb"')).to eq('path/with spaces.rb')
    end

    it 'unescapes paths with tab characters' do
      # Git escapes tab as \t
      expect(described_class.unescape_path('"path/with\\ttab.rb"')).to eq("path/with\ttab.rb")
    end

    it 'unescapes paths with newline characters' do
      # Git escapes newline as \n
      expect(described_class.unescape_path('"path/with\\nnewline.rb"')).to eq("path/with\nnewline.rb")
    end

    it 'unescapes paths with embedded quotes' do
      # Git escapes double quote as \"
      expect(described_class.unescape_path('"path/with\\"quote.rb"')).to eq('path/with"quote.rb')
    end

    it 'unescapes paths with backslashes' do
      # Git escapes backslash as \\
      expect(described_class.unescape_path('"path/with\\\\backslash.rb"')).to eq('path/with\\backslash.rb')
    end

    it 'unescapes paths with UTF-8 characters (octal encoding)' do
      # Git encodes UTF-8 bytes as octal sequences
      # ☠ (skull and crossbones) is U+2620, UTF-8: E2 98 A0, octal: 342 230 240
      expect(described_class.unescape_path('"path/with\\342\\230\\240skull.rb"')).to eq('path/with☠skull.rb')
    end

    it 'unescapes paths with multiple special characters' do
      # Combination: space, tab, UTF-8
      input = '"dir with spaces/file\\twith\\ttabs\\342\\230\\240.rb"'
      expected = "dir with spaces/file\twith\ttabs☠.rb"
      expect(described_class.unescape_path(input)).to eq(expected)
    end

    it 'handles paths starting with quotes in filename' do
      # A file literally named "quoted" (with quotes) would be escaped
      expect(described_class.unescape_path('"\\"quoted\\".rb"')).to eq('"quoted".rb')
    end

    it 'handles nil' do
      expect(described_class.unescape_path(nil)).to be_nil
    end
  end

  describe '.build_result' do
    it 'creates a DiffResult with the provided components' do
      files = [double('file1'), double('file2')]
      shortstat = { files_changed: 2, insertions: 10, deletions: 5 }
      dirstat = Git::DirstatInfo.new(entries: [])

      result = described_class.build_result(files: files, shortstat: shortstat, dirstat: dirstat)

      expect(result).to be_a(Git::DiffResult)
      expect(result.files_changed).to eq(2)
      expect(result.total_insertions).to eq(10)
      expect(result.total_deletions).to eq(5)
      expect(result.files).to eq(files)
      expect(result.dirstat).to eq(dirstat)
    end
  end

  describe '.empty_result' do
    it 'returns a DiffResult with zero values' do
      result = described_class.empty_result

      expect(result).to be_a(Git::DiffResult)
      expect(result.files_changed).to eq(0)
      expect(result.total_insertions).to eq(0)
      expect(result.total_deletions).to eq(0)
      expect(result.files).to be_empty
      expect(result.dirstat).to be_nil
    end
  end
end

RSpec.describe Git::DiffParser::Numstat do
  describe '.parse' do
    it 'returns empty result for empty output' do
      result = described_class.parse('')

      expect(result.files).to be_empty
      expect(result.files_changed).to eq(0)
    end

    it 'parses numstat output with shortstat' do
      output = <<~OUTPUT
        10\t5\tlib/file1.rb
        3\t1\tlib/file2.rb
         2 files changed, 13 insertions(+), 6 deletions(-)
      OUTPUT

      result = described_class.parse(output)

      expect(result).to be_a(Git::DiffResult)
      expect(result.files_changed).to eq(2)
      expect(result.total_insertions).to eq(13)
      expect(result.total_deletions).to eq(6)
      expect(result.files.size).to eq(2)
      expect(result.files[0].path).to eq('lib/file1.rb')
      expect(result.files[0].insertions).to eq(10)
      expect(result.files[0].deletions).to eq(5)
    end

    it 'parses renamed files' do
      output = <<~OUTPUT
        5\t2\told.rb => new.rb
         1 file changed, 5 insertions(+), 2 deletions(-)
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].path).to eq('new.rb')
      expect(result.files[0].src_path).to eq('old.rb')
    end

    it 'parses brace-style renamed paths' do
      output = <<~OUTPUT
        5\t2\tlib/{old.rb => new.rb}
         1 file changed, 5 insertions(+), 2 deletions(-)
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].path).to eq('lib/new.rb')
      expect(result.files[0].src_path).to eq('lib/old.rb')
    end

    it 'includes dirstat when requested' do
      output = <<~OUTPUT
        10\t5\tlib/file.rb
         1 file changed, 10 insertions(+), 5 deletions(-)
        100.0% lib/
      OUTPUT

      result = described_class.parse(output, include_dirstat: true)

      expect(result.dirstat).not_to be_nil
      expect(result.dirstat.entries.size).to eq(1)
      expect(result.dirstat.entries[0].percentage).to eq(100.0)
    end
  end

  describe '.parse_as_map' do
    it 'returns a hash of path to stats' do
      lines = [
        "10\t5\tlib/file1.rb",
        "3\t1\tlib/file2.rb"
      ]

      result = described_class.parse_as_map(lines)

      expect(result['lib/file1.rb']).to eq(insertions: 10, deletions: 5)
      expect(result['lib/file2.rb']).to eq(insertions: 3, deletions: 1)
    end

    it 'includes binary flag when requested' do
      lines = [
        "-\t-\timage.png",
        "10\t5\tfile.rb"
      ]

      result = described_class.parse_as_map(lines, include_binary: true)

      expect(result['image.png']).to eq(insertions: 0, deletions: 0, binary: true)
      expect(result['file.rb']).to eq(insertions: 10, deletions: 5, binary: false)
    end

    it 'normalizes rename paths to destination path as key' do
      lines = [
        "5\t2\told.rb => new.rb",
        "3\t1\tlib/{old_name.rb => new_name.rb}"
      ]

      result = described_class.parse_as_map(lines)

      # Keys should be the destination paths, not the raw rename format
      expect(result['new.rb']).to eq(insertions: 5, deletions: 2)
      expect(result['lib/new_name.rb']).to eq(insertions: 3, deletions: 1)
      # Old keys should not exist
      expect(result).not_to have_key('old.rb => new.rb')
      expect(result).not_to have_key('lib/{old_name.rb => new_name.rb}')
    end

    it 'handles quoted paths with special characters' do
      lines = [
        "10\t5\t\"path/with\\ttab.rb\"",
        "3\t1\t\"file\\342\\230\\240.rb\""
      ]

      result = described_class.parse_as_map(lines)

      expect(result["path/with\ttab.rb"]).to eq(insertions: 10, deletions: 5)
      expect(result['file☠.rb']).to eq(insertions: 3, deletions: 1)
    end

    it 'handles quoted renamed paths with special characters' do
      lines = [
        "5\t2\t\"old\\ttab.rb\" => \"new\\ttab.rb\"",
        "3\t1\t\"{old\\342\\230\\240.rb => new\\342\\230\\240.rb}\""
      ]

      result = described_class.parse_as_map(lines)

      # Keys should be unescaped destination paths
      expect(result["new\ttab.rb"]).to eq(insertions: 5, deletions: 2)
      expect(result['new☠.rb']).to eq(insertions: 3, deletions: 1)
    end
  end
end

RSpec.describe Git::DiffParser::Raw do
  describe '.parse' do
    it 'returns empty result for empty output' do
      result = described_class.parse('')

      expect(result.files).to be_empty
      expect(result.files_changed).to eq(0)
    end

    it 'parses raw output with numstat and shortstat' do
      output = <<~OUTPUT
        :100644 100644 abc1234 def5678 M\tlib/file.rb
        10\t5\tlib/file.rb
         1 file changed, 10 insertions(+), 5 deletions(-)
      OUTPUT

      result = described_class.parse(output)

      expect(result).to be_a(Git::DiffResult)
      expect(result.files_changed).to eq(1)
      expect(result.files.size).to eq(1)

      file = result.files[0]
      expect(file.status).to eq(:modified)
      expect(file.src.path).to eq('lib/file.rb')
      expect(file.dst.path).to eq('lib/file.rb')
      expect(file.insertions).to eq(10)
      expect(file.deletions).to eq(5)
    end

    it 'parses renamed files' do
      output = <<~OUTPUT
        :100644 100644 abc1234 def5678 R075\told.rb\tnew.rb
        5\t2\tnew.rb
         1 file changed, 5 insertions(+), 2 deletions(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:renamed)
      expect(file.similarity).to eq(75)
      expect(file.src.path).to eq('old.rb')
      expect(file.dst.path).to eq('new.rb')
    end

    it 'parses 100% rename (pure move with no content change)' do
      output = <<~OUTPUT
        :100644 100644 abc1234 abc1234 R100\told.rb\tnew.rb
        0\t0\tnew.rb
         1 file changed, 0 insertions(+), 0 deletions(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:renamed)
      expect(file.similarity).to eq(100)
      expect(file.src.path).to eq('old.rb')
      expect(file.dst.path).to eq('new.rb')
      # Same SHA means no content change
      expect(file.src.sha).to eq(file.dst.sha)
      expect(file.insertions).to eq(0)
      expect(file.deletions).to eq(0)
    end

    it 'matches stats for renamed files with brace-style numstat paths' do
      # When numstat outputs brace-style rename paths like lib/{old => new}.rb,
      # the parser must normalize this to the destination path to match raw output
      output = <<~OUTPUT
        :100644 100644 abc1234 def5678 R090\tlib/old.rb\tlib/new.rb
        5\t2\tlib/{old.rb => new.rb}
         1 file changed, 5 insertions(+), 2 deletions(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.dst.path).to eq('lib/new.rb')
      expect(file.insertions).to eq(5)
      expect(file.deletions).to eq(2)
    end

    it 'parses added files' do
      output = <<~OUTPUT
        :000000 100644 0000000 abc1234 A\tnew_file.rb
        10\t0\tnew_file.rb
         1 file changed, 10 insertions(+)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:added)
      expect(file.src).to be_nil
      expect(file.dst.path).to eq('new_file.rb')
    end

    it 'parses deleted files' do
      output = <<~OUTPUT
        :100644 000000 abc1234 0000000 D\told_file.rb
        0\t10\told_file.rb
         1 file changed, 10 deletions(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:deleted)
      expect(file.src.path).to eq('old_file.rb')
      expect(file.dst).to be_nil
    end

    it 'parses added submodule (mode 160000)' do
      output = <<~OUTPUT
        :000000 160000 0000000 abc1234 A\tvendor/submodule
        1\t0\tvendor/submodule
         1 file changed, 1 insertion(+)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:added)
      expect(file.src).to be_nil
      expect(file.dst.mode).to eq('160000')
      expect(file.dst.path).to eq('vendor/submodule')
    end

    it 'parses modified submodule (mode 160000)' do
      output = <<~OUTPUT
        :160000 160000 abc1234 def5678 M\tvendor/submodule
        1\t1\tvendor/submodule
         1 file changed, 1 insertion(+), 1 deletion(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:modified)
      expect(file.src.mode).to eq('160000')
      expect(file.dst.mode).to eq('160000')
      expect(file.dst.path).to eq('vendor/submodule')
    end

    it 'parses paths with tab characters' do
      # Tab is escaped as \t in quoted paths, but raw format uses actual tab as delimiter
      # Paths containing tabs would be quoted
      output = <<~OUTPUT
        :100644 100644 abc1234 def5678 M\t"path/with\\ttab.rb"
        10\t5\t"path/with\\ttab.rb"
         1 file changed, 10 insertions(+), 5 deletions(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.dst.path).to eq("path/with\ttab.rb")
      expect(file.src.path).to eq("path/with\ttab.rb")
    end

    it 'parses paths with UTF-8 characters (octal encoding)' do
      output = <<~OUTPUT
        :100644 100644 abc1234 def5678 M\t"file\\342\\230\\240.rb"
        10\t5\t"file\\342\\230\\240.rb"
         1 file changed, 10 insertions(+), 5 deletions(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.dst.path).to eq('file☠.rb')
    end

    it 'parses renamed paths with special characters' do
      output = <<~OUTPUT
        :100644 100644 abc1234 def5678 R100\t"old\\ttab.rb"\t"new\\ttab.rb"
        5\t2\t"new\\ttab.rb"
         1 file changed, 5 insertions(+), 2 deletions(-)
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:renamed)
      expect(file.src.path).to eq("old\ttab.rb")
      expect(file.dst.path).to eq("new\ttab.rb")
    end
  end
end

RSpec.describe Git::DiffParser::Patch do
  describe '.parse' do
    it 'returns empty result for empty output' do
      result = described_class.parse('')

      expect(result.files).to be_empty
      expect(result.files_changed).to eq(0)
    end

    it 'parses patch output with numstat and shortstat' do
      output = <<~OUTPUT
        10\t5\tlib/file.rb
         1 file changed, 10 insertions(+), 5 deletions(-)
        diff --git a/lib/file.rb b/lib/file.rb
        index abc1234..def5678 100644
        --- a/lib/file.rb
        +++ b/lib/file.rb
        @@ -1,5 +1,10 @@
        +new line
         existing line
      OUTPUT

      result = described_class.parse(output)

      expect(result).to be_a(Git::DiffResult)
      expect(result.files_changed).to eq(1)
      expect(result.files.size).to eq(1)

      file = result.files[0]
      expect(file.src.path).to eq('lib/file.rb')
      expect(file.dst.path).to eq('lib/file.rb')
      expect(file.insertions).to eq(10)
      expect(file.deletions).to eq(5)
      expect(file.patch).to include('diff --git')
      expect(file.patch).to include('+new line')
    end

    it 'parses new files' do
      output = <<~OUTPUT
        10\t0\tnew_file.rb
         1 file changed, 10 insertions(+)
        diff --git a/new_file.rb b/new_file.rb
        new file mode 100644
        index 0000000..abc1234
        --- /dev/null
        +++ b/new_file.rb
        @@ -0,0 +1,10 @@
        +content
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:added)
      expect(file.src).to be_nil
      expect(file.dst.path).to eq('new_file.rb')
    end

    it 'parses deleted files' do
      output = <<~OUTPUT
        0\t10\told_file.rb
         1 file changed, 10 deletions(-)
        diff --git a/old_file.rb b/old_file.rb
        deleted file mode 100644
        index abc1234..0000000
        --- a/old_file.rb
        +++ /dev/null
        @@ -1,10 +0,0 @@
        -content
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:deleted)
      expect(file.src.path).to eq('old_file.rb')
      expect(file.dst).to be_nil
    end

    it 'parses renamed files with similarity' do
      output = <<~OUTPUT
        5\t2\tnew_name.rb
         1 file changed, 5 insertions(+), 2 deletions(-)
        diff --git a/old_name.rb b/new_name.rb
        similarity index 85%
        rename from old_name.rb
        rename to new_name.rb
        index abc1234..def5678 100644
        --- a/old_name.rb
        +++ b/new_name.rb
        @@ -1,5 +1,8 @@
         content
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:renamed)
      expect(file.similarity).to eq(85)
      expect(file.src.path).to eq('old_name.rb')
      expect(file.dst.path).to eq('new_name.rb')
    end

    it 'parses 100% rename (pure move with no content change)' do
      output = <<~OUTPUT
        0\t0\tnew_name.rb
         1 file changed, 0 insertions(+), 0 deletions(-)
        diff --git a/old_name.rb b/new_name.rb
        similarity index 100%
        rename from old_name.rb
        rename to new_name.rb
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:renamed)
      expect(file.similarity).to eq(100)
      expect(file.src.path).to eq('old_name.rb')
      expect(file.dst.path).to eq('new_name.rb')
      expect(file.insertions).to eq(0)
      expect(file.deletions).to eq(0)
      # No patch content for pure rename
      expect(file.patch).not_to include('@@')
    end

    it 'matches stats for renamed files with brace-style numstat paths' do
      # When numstat outputs brace-style rename paths like lib/{old => new}.rb,
      # the parser must normalize this to the destination path to match patch output
      output = <<~OUTPUT
        8\t3\tlib/{old_name.rb => new_name.rb}
         1 file changed, 8 insertions(+), 3 deletions(-)
        diff --git a/lib/old_name.rb b/lib/new_name.rb
        similarity index 75%
        rename from lib/old_name.rb
        rename to lib/new_name.rb
        index abc1234..def5678 100644
        --- a/lib/old_name.rb
        +++ b/lib/new_name.rb
        @@ -1,5 +1,10 @@
         content
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.dst.path).to eq('lib/new_name.rb')
      expect(file.insertions).to eq(8)
      expect(file.deletions).to eq(3)
    end

    it 'parses copied files with similarity' do
      output = <<~OUTPUT
        10\t0\tcopy_of_file.rb
         1 file changed, 10 insertions(+)
        diff --git a/original.rb b/copy_of_file.rb
        similarity index 90%
        copy from original.rb
        copy to copy_of_file.rb
        index abc1234..def5678 100644
        --- a/original.rb
        +++ b/copy_of_file.rb
        @@ -1,5 +1,15 @@
         content
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:copied)
      expect(file.similarity).to eq(90)
      expect(file.src.path).to eq('original.rb')
      expect(file.dst.path).to eq('copy_of_file.rb')
    end

    it 'parses binary files' do
      output = <<~OUTPUT
        -\t-\timage.png
         1 file changed, 0 insertions(+), 0 deletions(-)
        diff --git a/image.png b/image.png
        index abc1234..def5678 100644
        Binary files a/image.png and b/image.png differ
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.binary).to be true
    end

    it 'detects GIT binary patch format as binary' do
      output = <<~OUTPUT
        -\t-\timage.png
         1 file changed, 0 insertions(+), 0 deletions(-)
        diff --git a/image.png b/image.png
        index abc1234..def5678 100644
        GIT binary patch
        literal 1234
        zcmV;@1
        diff --git a/other.rb b/other.rb
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].binary).to be true
      expect(result.files[0].path).to eq('image.png')
    end

    it 'parses multiple files in one diff' do
      output = <<~OUTPUT
        10\t5\tlib/file1.rb
        3\t2\tlib/file2.rb
         2 files changed, 13 insertions(+), 7 deletions(-)
        diff --git a/lib/file1.rb b/lib/file1.rb
        index abc1234..def5678 100644
        --- a/lib/file1.rb
        +++ b/lib/file1.rb
        @@ -1,5 +1,10 @@
        +new line
        diff --git a/lib/file2.rb b/lib/file2.rb
        index 111aaaa..222bbbb 100644
        --- a/lib/file2.rb
        +++ b/lib/file2.rb
        @@ -1,3 +1,4 @@
        +another new line
      OUTPUT

      result = described_class.parse(output)

      expect(result.files.size).to eq(2)
      expect(result.files[0].path).to eq('lib/file1.rb')
      expect(result.files[0].insertions).to eq(10)
      expect(result.files[1].path).to eq('lib/file2.rb')
      expect(result.files[1].insertions).to eq(3)
    end

    it 'parses diff with both rename and copy in same output' do
      output = <<~OUTPUT
        5\t2\trenamed.rb
        3\t1\tcopied.rb
         2 files changed, 8 insertions(+), 3 deletions(-)
        diff --git a/original.rb b/renamed.rb
        similarity index 85%
        rename from original.rb
        rename to renamed.rb
        index abc1234..def5678 100644
        --- a/original.rb
        +++ b/renamed.rb
        @@ -1,5 +1,8 @@
         content
        diff --git a/source.rb b/copied.rb
        similarity index 90%
        copy from source.rb
        copy to copied.rb
        index 111aaaa..222bbbb 100644
        --- a/source.rb
        +++ b/copied.rb
        @@ -1,3 +1,5 @@
         content
      OUTPUT

      result = described_class.parse(output)

      expect(result.files.size).to eq(2)

      renamed = result.files.find { |f| f.path == 'renamed.rb' }
      expect(renamed).not_to be_nil
      expect(renamed.status).to eq(:renamed)
      expect(renamed.src_path).to eq('original.rb')
      expect(renamed.similarity).to eq(85)
      expect(renamed.insertions).to eq(5)
      expect(renamed.deletions).to eq(2)

      copied = result.files.find { |f| f.path == 'copied.rb' }
      expect(copied).not_to be_nil
      expect(copied.status).to eq(:copied)
      expect(copied.src_path).to eq('source.rb')
      expect(copied.similarity).to eq(90)
      expect(copied.insertions).to eq(3)
      expect(copied.deletions).to eq(1)
    end

    it 'handles mode changes (executable bit)' do
      output = <<~OUTPUT
        0\t0\tbin/script
         1 file changed, 0 insertions(+), 0 deletions(-)
        diff --git a/bin/script b/bin/script
        old mode 100644
        new mode 100755
      OUTPUT

      result = described_class.parse(output)

      expect(result.files.size).to eq(1)
      file = result.files[0]
      expect(file.path).to eq('bin/script')
      expect(file.src.mode).to eq('100644')
      expect(file.dst.mode).to eq('100755')
      # Same file type (100), just different permissions - stays :modified
      expect(file.status).to eq(:modified)
    end

    it 'detects type change from regular file to symlink' do
      output = <<~OUTPUT
        0\t0\tlink_file
         1 file changed, 0 insertions(+), 0 deletions(-)
        diff --git a/link_file b/link_file
        old mode 100644
        new mode 120000
        index abc1234..def5678
        --- a/link_file
        +++ b/link_file
        @@ -1 +1 @@
        -content
        +target
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:type_changed)
      expect(file.src.mode).to eq('100644')
      expect(file.dst.mode).to eq('120000')
    end

    it 'detects type change from symlink to regular file' do
      output = <<~OUTPUT
        1\t1\tformer_link
         1 file changed, 1 insertion(+), 1 deletion(-)
        diff --git a/former_link b/former_link
        old mode 120000
        new mode 100644
        index abc1234..def5678
        --- a/former_link
        +++ b/former_link
        @@ -1 +1 @@
        -target
        +actual content
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:type_changed)
      expect(file.src.mode).to eq('120000')
      expect(file.dst.mode).to eq('100644')
    end

    it 'parses added submodule (mode 160000)' do
      output = <<~OUTPUT
        1\t0\tvendor/submodule
         1 file changed, 1 insertion(+)
        diff --git a/vendor/submodule b/vendor/submodule
        new file mode 160000
        index 0000000..abc1234
        --- /dev/null
        +++ b/vendor/submodule
        @@ -0,0 +1 @@
        +Subproject commit abc1234567890
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:added)
      expect(file.src).to be_nil
      expect(file.dst.mode).to eq('160000')
      expect(file.dst.path).to eq('vendor/submodule')
    end

    it 'parses modified submodule (mode 160000)' do
      output = <<~OUTPUT
        1\t1\tvendor/submodule
         1 file changed, 1 insertion(+), 1 deletion(-)
        diff --git a/vendor/submodule b/vendor/submodule
        index abc1234..def5678 160000
        --- a/vendor/submodule
        +++ b/vendor/submodule
        @@ -1 +1 @@
        -Subproject commit abc1234567890
        +Subproject commit def5678901234
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.status).to eq(:modified)
      expect(file.src.mode).to eq('160000')
      expect(file.dst.mode).to eq('160000')
      expect(file.dst.path).to eq('vendor/submodule')
    end

    it 'handles quoted paths with special characters' do
      output = <<~OUTPUT
        5\t2\t"path/with spaces/file.rb"
         1 file changed, 5 insertions(+), 2 deletions(-)
        diff --git "a/path/with spaces/file.rb" "b/path/with spaces/file.rb"
        index abc1234..def5678 100644
        --- "a/path/with spaces/file.rb"
        +++ "b/path/with spaces/file.rb"
        @@ -1,3 +1,6 @@
        +content
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].path).to eq('path/with spaces/file.rb')
    end

    it 'handles paths with tab characters' do
      # Tab in filename is escaped as \t
      output = <<~OUTPUT
        5\t2\t"path/with\\ttab.rb"
         1 file changed, 5 insertions(+), 2 deletions(-)
        diff --git "a/path/with\\ttab.rb" "b/path/with\\ttab.rb"
        index abc1234..def5678 100644
        --- "a/path/with\\ttab.rb"
        +++ "b/path/with\\ttab.rb"
        @@ -1,3 +1,6 @@
        +content
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].path).to eq("path/with\ttab.rb")
    end

    it 'handles paths with UTF-8 characters (octal encoding)' do
      # UTF-8 skull ☠ (U+2620) encoded as octal: \342\230\240
      output = <<~OUTPUT
        5\t2\t"file\\342\\230\\240.rb"
         1 file changed, 5 insertions(+), 2 deletions(-)
        diff --git "a/file\\342\\230\\240.rb" "b/file\\342\\230\\240.rb"
        index abc1234..def5678 100644
        --- "a/file\\342\\230\\240.rb"
        +++ "b/file\\342\\230\\240.rb"
        @@ -1,3 +1,6 @@
        +content
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].path).to eq('file☠.rb')
    end

    it 'handles paths with newline characters' do
      # Newline in filename is escaped as \n
      output = <<~OUTPUT
        5\t2\t"path/with\\nnewline.rb"
         1 file changed, 5 insertions(+), 2 deletions(-)
        diff --git "a/path/with\\nnewline.rb" "b/path/with\\nnewline.rb"
        index abc1234..def5678 100644
        --- "a/path/with\\nnewline.rb"
        +++ "b/path/with\\nnewline.rb"
        @@ -1,3 +1,6 @@
        +content
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].path).to eq("path/with\nnewline.rb")
    end

    it 'handles paths with embedded quotes' do
      # Double quote in filename is escaped as \"
      output = <<~OUTPUT
        5\t2\t"path/with\\"quote.rb"
         1 file changed, 5 insertions(+), 2 deletions(-)
        diff --git "a/path/with\\"quote.rb" "b/path/with\\"quote.rb"
        index abc1234..def5678 100644
        --- "a/path/with\\"quote.rb"
        +++ "b/path/with\\"quote.rb"
        @@ -1,3 +1,6 @@
        +content
      OUTPUT

      result = described_class.parse(output)

      expect(result.files[0].path).to eq('path/with"quote.rb')
    end

    it 'handles renamed paths with special characters' do
      output = <<~OUTPUT
        5\t2\t"old\\342\\230\\240.rb" => "new\\342\\230\\240.rb"
         1 file changed, 5 insertions(+), 2 deletions(-)
        diff --git "a/old\\342\\230\\240.rb" "b/new\\342\\230\\240.rb"
        similarity index 95%
        rename from "old\\342\\230\\240.rb"
        rename to "new\\342\\230\\240.rb"
        index abc1234..def5678 100644
        --- "a/old\\342\\230\\240.rb"
        +++ "b/new\\342\\230\\240.rb"
        @@ -1,3 +1,6 @@
        +content
      OUTPUT

      result = described_class.parse(output)
      file = result.files[0]

      expect(file.src_path).to eq('old☠.rb')
      expect(file.path).to eq('new☠.rb')
    end
  end
end
