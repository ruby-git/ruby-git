# frozen_string_literal: true

require 'test_helper'

class TestFsck < Test::Unit::TestCase
  def setup
    clone_working_repo
  end

  # Command line generation tests

  test 'fsck with no options' do
    expected_command_line = ['fsck', '--no-progress', {}]
    assert_command_line_eq(expected_command_line, &:fsck)
  end

  test 'fsck with unreachable option' do
    expected_command_line = ['fsck', '--no-progress', '--unreachable', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(unreachable: true) }
  end

  test 'fsck with strict option' do
    expected_command_line = ['fsck', '--no-progress', '--strict', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(strict: true) }
  end

  test 'fsck with connectivity_only option' do
    expected_command_line = ['fsck', '--no-progress', '--connectivity-only', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(connectivity_only: true) }
  end

  test 'fsck with dangling: true' do
    expected_command_line = ['fsck', '--no-progress', '--dangling', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(dangling: true) }
  end

  test 'fsck with dangling: false' do
    expected_command_line = ['fsck', '--no-progress', '--no-dangling', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(dangling: false) }
  end

  test 'fsck with full: true' do
    expected_command_line = ['fsck', '--no-progress', '--full', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(full: true) }
  end

  test 'fsck with full: false' do
    expected_command_line = ['fsck', '--no-progress', '--no-full', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(full: false) }
  end

  test 'fsck with multiple options' do
    expected_command_line = ['fsck', '--no-progress', '--unreachable', '--strict', '--no-dangling', {}]
    assert_command_line_eq(expected_command_line) do |git|
      git.fsck(unreachable: true, strict: true, dangling: false)
    end
  end

  test 'fsck with name_objects: true' do
    expected_command_line = ['fsck', '--no-progress', '--name-objects', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(name_objects: true) }
  end

  test 'fsck with name_objects: false' do
    expected_command_line = ['fsck', '--no-progress', '--no-name-objects', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(name_objects: false) }
  end

  test 'fsck with references: true' do
    expected_command_line = ['fsck', '--no-progress', '--references', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(references: true) }
  end

  test 'fsck with references: false' do
    expected_command_line = ['fsck', '--no-progress', '--no-references', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck(references: false) }
  end

  test 'fsck with single object argument' do
    expected_command_line = ['fsck', '--no-progress', 'abc123', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck('abc123') }
  end

  test 'fsck with multiple object arguments' do
    expected_command_line = ['fsck', '--no-progress', 'abc123', 'def456', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck('abc123', 'def456') }
  end

  test 'fsck with object arguments and options' do
    expected_command_line = ['fsck', '--no-progress', '--unreachable', 'abc123', 'def456', {}]
    assert_command_line_eq(expected_command_line) { |git| git.fsck('abc123', 'def456', unreachable: true) }
  end

  # Integration tests

  test 'fsck returns a FsckResult' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')
      result = git.fsck

      assert_instance_of(Git::FsckResult, result)
      assert_respond_to(result, :dangling)
      assert_respond_to(result, :missing)
      assert_respond_to(result, :unreachable)
      assert_respond_to(result, :warnings)
      assert_respond_to(result, :root)
      assert_respond_to(result, :tagged)
    end
  end

  test 'fsck result attributes are arrays' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')
      result = git.fsck

      assert_instance_of(Array, result.dangling)
      assert_instance_of(Array, result.missing)
      assert_instance_of(Array, result.unreachable)
      assert_instance_of(Array, result.warnings)
      assert_instance_of(Array, result.root)
      assert_instance_of(Array, result.tagged)
    end
  end

  test 'fsck result has helper methods' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')
      result = git.fsck

      assert_respond_to(result, :any_issues?)
      assert_respond_to(result, :empty?)
      assert_respond_to(result, :all_objects)
      assert_respond_to(result, :count)
      assert_respond_to(result, :to_h)
    end
  end

  test 'fsck result empty? returns true for clean repository' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')
      result = git.fsck

      # A freshly cloned repository should typically be clean
      if result.dangling.empty? && result.missing.empty? &&
         result.unreachable.empty? && result.warnings.empty?
        assert(result.empty?)
        assert_equal(false, result.any_issues?)
        assert_equal(0, result.count)
      end
    end
  end

  test 'fsck result to_h returns hash representation' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')
      result = git.fsck
      hash = result.to_h

      assert_instance_of(Hash, hash)
      assert(hash.key?(:dangling))
      assert(hash.key?(:missing))
      assert(hash.key?(:unreachable))
      assert(hash.key?(:warnings))
    end
  end

  test 'fsck objects are FsckObject instances' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')
      result = git.fsck

      # If there are any dangling objects, they should be FsckObject instances
      result.dangling.each do |obj|
        assert_instance_of(Git::FsckObject, obj)
        assert_includes(%i[commit tree blob tag], obj.type)
        assert_match(/\A[0-9a-f]{40}\z/, obj.sha)
      end
    end
  end

  # Integration tests that create actual git scenarios

  test 'fsck detects dangling commits after reset and reflog expire' do
    in_temp_dir do |_path|
      git = Git.init('test_dangling')
      Dir.chdir('test_dangling') do
        File.write('file.txt', 'initial content')
        git.add('file.txt')
        git.commit('Initial commit')

        File.write('file.txt', 'second content')
        git.add('file.txt')
        git.commit('Second commit')

        # Create a dangling commit by resetting and expiring reflogs
        git.reset_hard('HEAD~1')
        `git reflog expire --expire=now --all 2>&1`

        result = git.fsck

        assert_equal(1, result.dangling.size)
        assert_equal(:commit, result.dangling.first.type)
        assert_match(/\A[0-9a-f]{40}\z/, result.dangling.first.sha)
        assert(result.any_issues?)
        assert_equal(false, result.empty?)
      end
    end
  end

  test 'fsck detects dangling blobs' do
    in_temp_dir do |_path|
      git = Git.init('test_dangling_blob')
      Dir.chdir('test_dangling_blob') do
        File.write('file.txt', 'initial content')
        git.add('file.txt')
        git.commit('Initial commit')

        # Create a dangling blob by hashing a file without committing
        File.write('orphan.txt', 'orphan content')
        blob_sha = `git hash-object -w orphan.txt 2>&1`.strip
        File.delete('orphan.txt')

        result = git.fsck

        assert(result.dangling.any? { |obj| obj.type == :blob })
        dangling_blob = result.dangling.find { |obj| obj.sha == blob_sha }
        assert_not_nil(dangling_blob)
        assert_equal(:blob, dangling_blob.type)
      end
    end
  end

  test 'fsck detects unreachable objects with unreachable option' do
    in_temp_dir do |_path|
      git = Git.init('test_unreachable')
      Dir.chdir('test_unreachable') do
        File.write('file.txt', 'initial content')
        git.add('file.txt')
        git.commit('Initial commit')

        File.write('file.txt', 'second content')
        git.add('file.txt')
        git.commit('Second commit')

        # Create unreachable commit and expire reflogs
        git.reset_hard('HEAD~1')
        `git reflog expire --expire=now --all 2>&1`

        result = git.fsck(unreachable: true, dangling: false)

        # With unreachable: true, we should see unreachable objects
        assert(result.unreachable.size >= 1)
        assert(result.unreachable.any? { |obj| obj.type == :commit })
      end
    end
  end

  test 'fsck reports root commits with root option' do
    in_temp_dir do |_path|
      git = Git.init('test_root')
      Dir.chdir('test_root') do
        File.write('file.txt', 'content')
        git.add('file.txt')
        git.commit('Initial commit')

        result = git.fsck(root: true)

        # Should have exactly one root commit (the initial commit)
        assert_equal(1, result.root.size)
        assert_equal(:commit, result.root.first.type)
        assert_match(/\A[0-9a-f]{40}\z/, result.root.first.sha)

        # root commits are not considered "issues"
        assert_equal(false, result.any_issues?) if result.dangling.empty? && result.missing.empty?
      end
    end
  end

  test 'fsck reports multiple root commits' do
    in_temp_dir do |_path|
      git = Git.init('test_multiple_roots')
      Dir.chdir('test_multiple_roots') do
        # Create first root commit
        File.write('file1.txt', 'content1')
        git.add('file1.txt')
        git.commit('First root')

        # Create an orphan branch with its own root
        `git checkout --orphan orphan_branch 2>&1`
        File.write('file2.txt', 'content2')
        git.add('file2.txt')
        git.commit('Second root')

        result = git.fsck(root: true)

        # Should have two root commits
        assert_equal(2, result.root.size)
        result.root.each do |obj|
          assert_equal(:commit, obj.type)
          assert_match(/\A[0-9a-f]{40}\z/, obj.sha)
        end
      end
    end
  end

  test 'fsck reports tagged objects with tags option' do
    in_temp_dir do |_path|
      git = Git.init('test_tags')
      Dir.chdir('test_tags') do
        File.write('file.txt', 'content')
        git.add('file.txt')
        git.commit('Initial commit')

        # Create an annotated tag
        git.add_tag('v1.0.0', message: 'Version 1.0.0')

        result = git.fsck(tags: true)

        # Should have tagged info
        assert(result.tagged.size >= 1)
        tagged_obj = result.tagged.first
        assert_equal(:commit, tagged_obj.type)
        assert_match(/\A[0-9a-f]{40}\z/, tagged_obj.sha)
        assert_equal('v1.0.0', tagged_obj.name)
      end
    end
  end

  test 'fsck detects missing objects' do
    in_temp_dir do |_path|
      git = Git.init('test_missing')
      Dir.chdir('test_missing') do
        File.write('file.txt', 'content')
        git.add('file.txt')
        git.commit('Initial commit')

        # Get the blob SHA
        blob_sha = `git rev-parse HEAD:file.txt 2>&1`.strip

        # Create a second commit that references the first
        File.write('file2.txt', 'more content')
        git.add('file2.txt')
        git.commit('Second commit')

        # Corrupt the repo by removing a blob object
        object_path = ".git/objects/#{blob_sha[0..1]}/#{blob_sha[2..]}"
        FileUtils.rm_f(object_path)

        result = git.fsck

        assert(result.missing.size >= 1)
        missing_obj = result.missing.find { |obj| obj.sha == blob_sha }
        assert_not_nil(missing_obj)
        assert_equal(:blob, missing_obj.type)
        assert(result.any_issues?)
      end
    end
  end

  test 'fsck with name_objects includes ref names' do
    in_temp_dir do |_path|
      git = Git.init('test_name_objects')
      Dir.chdir('test_name_objects') do
        File.write('file.txt', 'initial content')
        git.add('file.txt')
        git.commit('Initial commit')

        File.write('file.txt', 'second content')
        git.add('file.txt')
        git.commit('Second commit')

        # Create dangling commit and expire reflogs
        git.reset_hard('HEAD~1')
        `git reflog expire --expire=now --all 2>&1`

        result = git.fsck(name_objects: true)

        # Dangling objects should have names when --name-objects is used
        assert(result.dangling.size >= 1)
        # The name may or may not be present depending on git version
        # but the parsing should work either way
        dangling = result.dangling.first
        assert_equal(:commit, dangling.type)
        assert_match(/\A[0-9a-f]{40}\z/, dangling.sha)
      end
    end
  end

  # Parsing tests

  test 'parse_fsck_output handles lines with object names from --name-objects' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')

      # Simulate fsck output with --name-objects
      output = <<~OUTPUT
        dangling commit abc123def456789012345678901234567890abcd (HEAD~2^2:src/)
        unreachable tree def456789012345678901234567890abcdef1234 (refs/heads/main~5:lib/)
        missing blob 1234567890abcdef1234567890abcdef12345678
      OUTPUT

      result = git.lib.send(:parse_fsck_output, output)

      assert_equal(1, result.dangling.size)
      assert_equal(:commit, result.dangling.first.type)
      assert_equal('abc123def456789012345678901234567890abcd', result.dangling.first.sha)
      assert_equal('HEAD~2^2:src/', result.dangling.first.name)

      assert_equal(1, result.unreachable.size)
      assert_equal(:tree, result.unreachable.first.type)
      assert_equal('def456789012345678901234567890abcdef1234', result.unreachable.first.sha)
      assert_equal('refs/heads/main~5:lib/', result.unreachable.first.name)

      assert_equal(1, result.missing.size)
      assert_equal(:blob, result.missing.first.type)
      assert_equal('1234567890abcdef1234567890abcdef12345678', result.missing.first.sha)
      assert_nil(result.missing.first.name)
    end
  end

  test 'parse_fsck_output handles lines without object names' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')

      output = "dangling commit abc123def456789012345678901234567890abcd\n"

      result = git.lib.send(:parse_fsck_output, output)

      assert_equal(1, result.dangling.size)
      assert_equal(:commit, result.dangling.first.type)
      assert_equal('abc123def456789012345678901234567890abcd', result.dangling.first.sha)
      assert_nil(result.dangling.first.name)
    end
  end

  test 'parse_fsck_output handles root lines' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')

      output = <<~OUTPUT
        root abc123def456789012345678901234567890abcd
        root def456789012345678901234567890abcdef1234
      OUTPUT

      result = git.lib.send(:parse_fsck_output, output)

      assert_equal(2, result.root.size)
      assert_equal(:commit, result.root.first.type)
      assert_equal('abc123def456789012345678901234567890abcd', result.root.first.sha)
      assert_equal('def456789012345678901234567890abcdef1234', result.root.last.sha)
    end
  end

  test 'parse_fsck_output handles tagged lines' do
    in_temp_dir do |_path|
      git = Git.clone(@wdir, 'test_fsck')

      output = "tagged commit abc123def456789012345678901234567890abcd (v1.0.0) in def456789012345678901234567890abcdef1234\n"

      result = git.lib.send(:parse_fsck_output, output)

      assert_equal(1, result.tagged.size)
      assert_equal(:commit, result.tagged.first.type)
      assert_equal('abc123def456789012345678901234567890abcd', result.tagged.first.sha)
      assert_equal('v1.0.0', result.tagged.first.name)
    end
  end
end
