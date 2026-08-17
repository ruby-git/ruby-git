# frozen_string_literal: true

require 'spec_helper'

# Integration coverage for the `LC_ALL` pin in `Git::ExecutionContext#env_overrides`.
#
# git's regex engine matches *characters* only when the pinned locale resolves to a
# UTF-8 `LC_CTYPE` in the child process. When it does not — because the pinned value
# names a locale the host has not generated — git matches *bytes* instead, and every
# pattern whose metacharacters span non-ASCII text silently returns no match with
# exit status zero. These examples drive the affected public surfaces against real
# git so a wrong pinned value fails the build instead of returning empty results.
#
# Each surface carries a metacharacter-free positive control, which matches
# byte-for-byte under any ctype. Without it, a rig that fails to deliver UTF-8 bytes
# to git is indistinguishable from a genuine no-match.
#
# Do not gate these examples on whether the pinned locale actually loads. A spec that
# skips itself wherever the locale is missing disappears in exactly the environments
# where this defect lives, which is how the defect survived unreported for eighteen
# months. Nor is there anything to gate on for Darwin: each branch of the pin names a
# locale that exists on the platform it applies to.
#
# Windows is the one platform that does need a gate, and it is a statement about git
# rather than about the locale — see {#skip_on_git_for_windows}.
#
# The `with perl_regexp` groups cover the supported workaround for that platform and
# are deliberately *not* gated on Windows: PCRE matches characters everywhere, which is
# the whole reason those surfaces expose the selector. They are gated on whether git was
# built with PCRE at all. `config` has no such group because `git config` value patterns
# are POSIX extended regular expressions with no PCRE mode — there is nothing to select.
#
RSpec.describe 'non-ASCII regex matching', :integration do
  include_context 'in an empty repository'

  # Non-ASCII text used as file content, commit message, and config value. `Ä` is two
  # bytes in UTF-8 (C3 84), so a leading `.` matches it only under a UTF-8 ctype.
  let(:text) { 'ÄPFEL sind gut' }

  # Case-sensitive pattern whose only metacharacter has to match a multi-byte character
  let(:metacharacter_pattern) { '^.PFEL' }

  before do
    write_file('w.txt', "#{text}\n")
    repo.add('w.txt')
    repo.commit(text)
    repo.config_set('test.desc', text)
  end

  # Skips an example that needs a metacharacter to match a whole multi-byte character
  #
  # Git for Windows matches *bytes* for `.` and for POSIX classes over non-ASCII text
  # no matter what `LC_ALL` says. Measured on windows-latest with git 2.55.0: the
  # `^.PFEL` and `^[[:alpha:]]PFEL` probes fail identically under `en_US.UTF-8`,
  # `C.UTF-8`, `C`, and no pin at all, while the literal controls, `-i` folding, and
  # `-P` all succeed under every one of them. So this is a property of git's bundled
  # regex on that platform, not of the pinned value, and predates the pin.
  #
  # This gate is therefore not the forbidden "skip when the pinned locale is missing"
  # — it does not consult the locale at all. It does mean these examples have no
  # discriminating power on Windows, which is accurate: neither does the pin.
  #
  def skip_on_git_for_windows
    return unless Gem.win_platform?

    skip 'Git for Windows matches bytes rather than characters for `.` and POSIX classes, ' \
         'identically under every LC_ALL value including the one this gem pins'
  end

  describe 'Git::Repository#grep' do
    it 'matches a literal non-ASCII pattern' do
      expect(repo.grep(text)).to eq('HEAD:w.txt' => [[1, text]])
    end

    it 'matches a case-sensitive pattern whose metacharacter spans a non-ASCII character' do
      skip_on_git_for_windows

      expect(repo.grep(metacharacter_pattern)).to eq('HEAD:w.txt' => [[1, text]])
    end

    it 'folds case across non-ASCII characters when ignore_case is given' do
      expect(repo.grep('äpfel sind gut', nil, ignore_case: true)).to eq('HEAD:w.txt' => [[1, text]])
    end

    context 'with perl_regexp', skip: unless_pcre('Git::Repository#grep with perl_regexp') do
      it 'matches a metacharacter against a non-ASCII character on every platform' do
        expect(repo.grep(metacharacter_pattern, nil, perl_regexp: true)).to eq('HEAD:w.txt' => [[1, text]])
      end
    end
  end

  describe 'Git::Repository#log' do
    it 'matches a literal non-ASCII commit message pattern' do
      expect(repo.log.grep(text).execute.size).to eq(1)
    end

    it 'matches a case-sensitive pattern whose metacharacter spans a non-ASCII character' do
      skip_on_git_for_windows

      expect(repo.log.grep(metacharacter_pattern).execute.size).to eq(1)
    end

    context 'with perl_regexp', skip: unless_pcre('Git::Log#perl_regexp') do
      it 'matches a metacharacter against a non-ASCII character on every platform' do
        expect(repo.log.perl_regexp.grep(metacharacter_pattern).execute.size).to eq(1)
      end
    end
  end

  describe 'Git::Repository#config_get_all' do
    it 'matches a literal non-ASCII value regex' do
      expect(repo.config_get_all('test.desc', text).map(&:value)).to eq([text])
    end

    it 'matches a case-sensitive value regex whose metacharacter spans a non-ASCII character' do
      skip_on_git_for_windows

      expect(repo.config_get_all('test.desc', metacharacter_pattern).map(&:value)).to eq([text])
    end
  end
end
