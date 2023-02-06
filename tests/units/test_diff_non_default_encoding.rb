#!/usr/bin/env ruby

require 'test_helper'

class TestDiffWithNonDefaultEncoding < Test::Unit::TestCase
  def git_working_dir
    create_temp_repo('encoding')
  end

  def setup
    @git = Git.open(git_working_dir)
  end

  def test_diff_with_greek_encoding
    d = @git.diff
    patch = d.patch
    return unless Encoding.default_external == (Encoding::UTF_8 rescue Encoding::UTF8) # skip test on Windows / check UTF8 in JRuby instead
    assert(patch.include?("-Φθγητ οπορτερε ιν ιδεριντ\n"))
    assert(patch.include?("+Φεθγιατ θρβανιτασ ρεπριμιqθε\n"))
  end

  def test_diff_with_japanese_and_korean_encoding
    d = @git.diff.path('test2.txt')
    patch = d.patch
    return unless Encoding.default_external == (Encoding::UTF_8 rescue Encoding::UTF8) # skip test on Windows / check UTF8 in JRuby instead
    expected_patch = <<~PATCH.chomp
      diff --git a/test2.txt b/test2.txt
      index 87d9aa8..210763e 100644
      --- a/test2.txt
      +++ b/test2.txt
      @@ -1,3 +1,3 @@
      -違いを生み出すサンプルテキスト
      -これは1行目です
      -これが最後の行です
      +이것은 파일이다
      +이것은 두 번째 줄입니다
      +이것이 마지막 줄입니다
    PATCH
    assert(patch.include?(expected_patch))
  end
end
