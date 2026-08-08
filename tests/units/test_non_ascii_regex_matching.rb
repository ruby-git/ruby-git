# frozen_string_literal: true

require 'test_helper'

# Coverage for the `LC_ALL` pin in `Git::Lib#env_overrides`.
#
# git's regex engine matches *characters* only when the pinned locale resolves to a
# UTF-8 `LC_CTYPE` in the child process. When it does not — because the pinned value
# names a locale the host has not generated — git matches *bytes* instead, and every
# pattern whose metacharacters span non-ASCII text silently returns no match with exit
# status zero. These tests drive the affected public surfaces against real git so a
# wrong pinned value fails the build instead of returning empty results.
#
# Each surface carries a metacharacter-free positive control, which matches
# byte-for-byte under any ctype. Without it, a rig that fails to deliver UTF-8 bytes to
# git is indistinguishable from a genuine no-match.
#
# Do not gate these tests on whether the pinned locale actually loads. A test that
# omits itself wherever the locale is missing disappears in exactly the environments
# where this defect lives, which is how the defect survived unreported for eighteen
# months. Nor is there anything to gate on for Darwin: each branch of the pin names a
# locale that exists on the platform it applies to.
#
# Windows is the one platform that does need a gate, and it is a statement about git
# rather than about the locale — see {#omit_on_git_for_windows}.
#
class TestNonAsciiRegexMatching < Test::Unit::TestCase
  # Non-ASCII text used as both file content and commit message. `Ä` is two bytes in
  # UTF-8 (C3 84), so a leading `.` matches it only under a UTF-8 ctype.
  TEXT = 'ÄPFEL sind gut'

  # Case-sensitive pattern whose only metacharacter has to match a multi-byte character
  METACHARACTER_PATTERN = '^.PFEL'

  # Omits a test that needs a metacharacter to match a whole multi-byte character
  #
  # Git for Windows matches *bytes* for `.` and for POSIX classes over non-ASCII text
  # no matter what `LC_ALL` says. Measured on windows-latest with git 2.55.0: the
  # `^.PFEL` and `^[[:alpha:]]PFEL` probes fail identically under `en_US.UTF-8`,
  # `C.UTF-8`, `C`, and no pin at all, while the literal controls, `-i` folding, and
  # `-P` all succeed under every one of them. So this is a property of git's bundled
  # regex on that platform, not of the pinned value, and predates the pin.
  #
  # This gate is therefore not the forbidden "omit when the pinned locale is missing" —
  # it does not consult the locale at all. It does mean these tests have no
  # discriminating power on Windows, which is accurate: neither does the pin.
  #
  def omit_on_git_for_windows
    return unless windows_platform?

    omit 'Git for Windows matches bytes rather than characters for `.` and POSIX classes, ' \
         'identically under every LC_ALL value including the one this gem pins'
  end

  # Yields a repository with TEXT as both the content of w.txt and the commit message
  def in_repo_with_non_ascii_content
    in_temp_dir do |_path|
      git = Git.init('test_project')
      Dir.chdir('test_project') do
        git.config('user.name', 'Test User')
        git.config('user.email', 'test@email.com')
        File.binwrite('w.txt', "#{TEXT}\n")
        git.add('w.txt')
        git.commit(TEXT)

        yield git
      end
    end
  end

  # The grep result is keyed by "<tree-ish>:<path>", and Git::Base#grep resolves
  # 'HEAD' to its sha before calling git
  def expected_grep_result(git)
    { "#{git.object('HEAD').sha}:w.txt" => [[1, TEXT]] }
  end

  test 'grep should match a literal non-ASCII pattern' do
    in_repo_with_non_ascii_content do |git|
      assert_equal expected_grep_result(git), git.grep(TEXT)
    end
  end

  test 'grep should match a case-sensitive pattern whose metacharacter spans a non-ASCII character' do
    omit_on_git_for_windows

    in_repo_with_non_ascii_content do |git|
      assert_equal expected_grep_result(git), git.grep(METACHARACTER_PATTERN)
    end
  end

  test 'grep should fold case across non-ASCII characters when ignore_case is given' do
    in_repo_with_non_ascii_content do |git|
      assert_equal expected_grep_result(git), git.grep('äpfel sind gut', nil, ignore_case: true)
    end
  end

  test 'log should match a literal non-ASCII commit message pattern' do
    in_repo_with_non_ascii_content do |git|
      assert_equal 1, git.log.grep(TEXT).execute.size
    end
  end

  test 'log should match a case-sensitive pattern whose metacharacter spans a non-ASCII character' do
    omit_on_git_for_windows

    in_repo_with_non_ascii_content do |git|
      assert_equal 1, git.log.grep(METACHARACTER_PATTERN).execute.size
    end
  end
end
