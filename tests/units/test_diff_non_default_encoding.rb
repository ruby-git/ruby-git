#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestDiffWithNonDefaultEncoding < Test::Unit::TestCase
  def git_working_dir
    cwd = `pwd`.chomp
    if File.directory?(File.join(cwd, 'files'))
      test_dir = File.join(cwd, 'files')
    elsif File.directory?(File.join(cwd, '..', 'files'))
      test_dir = File.join(cwd, '..', 'files')
    elsif File.directory?(File.join(cwd, 'tests', 'files'))
      test_dir = File.join(cwd, 'tests', 'files')
    end

    create_temp_repo(File.expand_path(File.join(test_dir, 'encoding')))
  end

  def create_temp_repo(clone_path)
    filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s.rjust(3, '0')
    @tmp_path = File.join("/tmp/", filename)
    FileUtils.mkdir_p(@tmp_path)
    FileUtils.cp_r(clone_path, @tmp_path)
    tmp_path = File.join(@tmp_path, File.basename(clone_path))
    Dir.chdir(tmp_path) do
      FileUtils.mv('dot_git', '.git')
    end
    tmp_path
  end

  def setup
    @git = Git.open(git_working_dir)
  end

  def test_diff_with_greek_encoding
    d = @git.diff
    patch = d.patch
    assert(patch.include?("-Φθγητ οπορτερε ιν ιδεριντ\n"))
    assert(patch.include?("+Φεθγιατ θρβανιτασ ρεπριμιqθε\n"))
  end

  def test_diff_with_japanese_and_korean_encoding
    d = @git.diff.path('test2.txt')
    patch = d.patch
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

