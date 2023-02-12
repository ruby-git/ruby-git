#!/usr/bin/env ruby

require 'test_helper'

class TestArchive < Test::Unit::TestCase

  def setup
    clone_working_repo
    @git = Git.open(@wdir)
    @tempfiles = []
  end

  def teardown
    @tempfiles.each { |f| File.delete(f) }
  end

  def tempfile
    Dir::Tmpname.create('test-archive') { }.tap do |f|
      @tempfiles << f
    end
  end

  def test_archive
    f = @git.archive('v2.6', tempfile)
    assert(File.exist?(f))
  end

  def test_archive_object
    f = @git.object('v2.6').archive(tempfile)  # writes to given file
    assert(File.exist?(f))
  end

  def test_archive_object_with_no_filename
    f = @git.object('v2.6').archive # returns path to temp file
    assert(File.exist?(f))
  end

  def test_archive_to_tar
    f = @git.object('v2.6').archive(nil, :format => 'tar') # returns path to temp file
    assert(File.exist?(f))

    lines = []
    Minitar::Input.open(f) do |tar_reader|
      lines = tar_reader.to_a.map(&:full_name)
    end

    assert_match(%r{ex_dir/}, lines[1])
    assert_match(/ex_dir\/ex\.txt/, lines[2])
    assert_match(/example\.txt/, lines[3])
  end

  def test_archive_to_zip
    f = @git.object('v2.6').archive(tempfile, :format => 'zip')
    assert(File.file?(f))
  end

  def test_archive_to_tgz
    f = @git.object('v2.6').archive(tempfile, :format => 'tgz', :prefix => 'test/')
    assert(File.exist?(f))

    lines = []
    File.open(f, 'rb') do |file_reader|
      Zlib::GzipReader.open(file_reader) do |gz_reader|
        Minitar::Input.open(gz_reader) do |tar_reader|
          lines = tar_reader.to_a.map(&:full_name)
        end
      end
    end

    assert_match(%r{test/}, lines[1])
    assert_match(%r{test/ex_dir/ex\.txt}, lines[3])
  end

  def test_archive_with_prefix_and_path
    f = @git.object('v2.6').archive(tempfile, :format => 'tar', :prefix => 'test/', :path => 'ex_dir/')
    assert(File.exist?(f))

    tar_file = Minitar::Input.open(f)
    lines = tar_file.each.to_a.map(&:full_name)
    tar_file.close
    assert_match(%r{test/}, lines[1])
    assert_match(%r{test/ex_dir/ex\.txt}, lines[3])
  end

  def test_archive_branch
    f = @git.remote('working').branch('master').archive(tempfile, :format => 'tgz')
    assert(File.exist?(f))
  end
end
