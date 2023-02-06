#!/usr/bin/env ruby

require 'test_helper'
require "fileutils"

class TestSignedCommits < Test::Unit::TestCase
  SSH_SIGNATURE_REGEXP = Regexp.new(<<~EOS.chomp, Regexp::MULTILINE)
    -----BEGIN SSH SIGNATURE-----
    .*
    -----END SSH SIGNATURE-----
  EOS

  def in_repo_with_signing_config(&block)
    in_temp_dir do |path|
      `git init`
      `ssh-keygen -t dsa -N "" -C "test key" -f .git/test-key`
      `git config --local gpg.format ssh`
      `git config --local user.signingkey .git/test-key`

      yield
    end
  end

  def test_commit_data
    in_repo_with_signing_config do
      create_file('README.md', '# My Project')
      `git add README.md`
      `git commit -S -m "Signed, sealed, delivered"`

      data = Git.open('.').lib.commit_data('HEAD')

      assert_match(SSH_SIGNATURE_REGEXP, data['gpgsig'])
      assert_equal("Signed, sealed, delivered\n", data['message'])
    end
  end
end
