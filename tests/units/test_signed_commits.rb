#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'
require "fileutils"

class TestSignedCommits < Test::Unit::TestCase
  def git_working_dir
    cwd = FileUtils.pwd
    if File.directory?(File.join(cwd, 'files'))
      test_dir = File.join(cwd, 'files')
    elsif File.directory?(File.join(cwd, '..', 'files'))
      test_dir = File.join(cwd, '..', 'files')
    elsif File.directory?(File.join(cwd, 'tests', 'files'))
      test_dir = File.join(cwd, 'tests', 'files')
    end

    create_temp_repo(File.expand_path(File.join(test_dir, 'signed_commits')))
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
    @lib = Git.open(git_working_dir).lib
  end

  def test_commit_data
    data = @lib.commit_data('a043c677c93d9f2b')

    assert_equal('Simon Coffey <simon.coffey@futurelearn.com> 1673868871 +0000', data['author'])
    assert_equal('92fd5b7c1aeb6a4e2602799f01608b3deebbad2d', data['tree'])
    assert_equal(<<~EOS.chomp, data['gpgsig'])
      -----BEGIN PGP SIGNATURE-----

      iHUEABYKAB0WIQRmiEtd91BkbBpcgV2yCJ+VnJz/iQUCY8U2cgAKCRCyCJ+VnJz/
      ibjyAP48dGdoFgWL2BjV3CnmebdVjEjTCQtF2QGUybJsyJhhcwEAwbzAAGt3YHfS
      uuLNH9ki9Sqd+/CH+L8Q2dPM5F4l3gg=
      =3ATn
      -----END PGP SIGNATURE-----
    EOS
    assert_equal(<<~EOS, data['message'])
      Signed commit

      This will allow me to test commit data extraction for signed commits.
      I'm making the message multiline to make sure that message extraction is
      preserved.
    EOS
  end
end
