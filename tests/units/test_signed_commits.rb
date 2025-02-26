# frozen_string_literal: true

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
      ssh_key_file = File.expand_path(File.join('.git', 'test-key'))
      `ssh-keygen -t dsa -N "" -C "test key" -f "#{ssh_key_file}"`
      `git config --local gpg.format ssh`
      `git config --local user.signingkey #{ssh_key_file}.pub`

      raise "ERROR: No .git/test-key file" unless File.exist?("#{ssh_key_file}.pub")

      yield
    end
  end

  def test_cat_file_commit
    # Signed commits should work on windows, but this test is omitted until the setup
    # on windows can be figured out
    omit('Omit testing of signed commits on Windows') if windows_platform?

    in_repo_with_signing_config do
      create_file('README.md', '# My Project')
      `git add README.md`
      `git commit -S -m "Signed, sealed, delivered"`

      data = Git.open('.').lib.cat_file_commit('HEAD')

      assert_match(SSH_SIGNATURE_REGEXP, data['gpgsig'])
      assert_equal("Signed, sealed, delivered\n", data['message'])
    end
  end
end
