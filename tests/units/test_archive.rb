#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestArchive < Test::Unit::TestCase

  def setup
    set_file_paths
    @git = Git.open(@wdir)
    @tempfiles = []
  end

  def teardown
    @tempfiles.clear
  end

  def tempfile
    tempfile_object = Tempfile.new('archive-test')
    @tempfiles << tempfile_object # prevent deletion until teardown
    tempfile_object.close # close to avoid locking from git processes
    tempfile_object.path
  end

  def test_archive
    f = @git.archive('v2.6', tempfile)
    assert(File.exist?(f))

    f = @git.object('v2.6').archive(tempfile)  # writes to given file
    assert(File.exist?(f))

    f = @git.object('v2.6').archive # returns path to temp file
    assert(File.exist?(f))

    f = @git.object('v2.6').archive(nil, :format => 'tar') # returns path to temp file
    assert(File.exist?(f))

    lines = Minitar::Input.open(f).each.to_a.map(&:full_name)
    assert_match(%r{ex_dir/}, lines[1])
    assert_match(/ex_dir\/ex\.txt/, lines[2])
    assert_match(/example\.txt/, lines[3])

    f = @git.object('v2.6').archive(tempfile, :format => 'zip')
    assert(File.file?(f))

    f = @git.object('v2.6').archive(tempfile, :format => 'tgz', :prefix => 'test/')
    assert(File.exist?(f))

    lines = Minitar::Input.open(Zlib::GzipReader.new(File.open(f, 'rb'))).each.to_a.map(&:full_name)
    assert_match(%r{test/}, lines[1])
    assert_match(%r{test/ex_dir/ex\.txt}, lines[3])

    f = @git.object('v2.6').archive(tempfile, :format => 'tar', :prefix => 'test/', :path => 'ex_dir/')
    assert(File.exist?(f))

    lines = Minitar::Input.open(f).each.to_a.map(&:full_name)
    assert_match(%r{test/}, lines[1])
    assert_match(%r{test/ex_dir/ex\.txt}, lines[3])

    in_temp_dir do
      c = Git.clone(@wbare, 'new')
      c.chdir do
        f = @git.remote('working').branch('master').archive(tempfile, :format => 'tgz')
        assert(File.exist?(f))
      end
    end
  end

end
