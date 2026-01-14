# frozen_string_literal: true

require 'test_helper'

class TestFsckResult < Test::Unit::TestCase
  test 'initialize with default empty arrays' do
    result = Git::FsckResult.new

    assert_equal([], result.dangling)
    assert_equal([], result.missing)
    assert_equal([], result.unreachable)
    assert_equal([], result.warnings)
    assert_equal([], result.root)
    assert_equal([], result.tagged)
  end

  test 'initialize with provided arrays' do
    dangling = [Git::FsckObject.new(type: :commit, sha: 'a' * 40)]
    missing = [Git::FsckObject.new(type: :blob, sha: 'b' * 40)]
    unreachable = [Git::FsckObject.new(type: :tree, sha: 'c' * 40)]
    warnings = [Git::FsckObject.new(type: :commit, sha: 'd' * 40, message: 'badTimezone')]

    result = Git::FsckResult.new(
      dangling: dangling,
      missing: missing,
      unreachable: unreachable,
      warnings: warnings
    )

    assert_equal(dangling, result.dangling)
    assert_equal(missing, result.missing)
    assert_equal(unreachable, result.unreachable)
    assert_equal(warnings, result.warnings)
  end

  test 'empty? returns true when all arrays are empty' do
    result = Git::FsckResult.new

    assert(result.empty?)
  end

  test 'empty? returns false when dangling is not empty' do
    dangling = [Git::FsckObject.new(type: :commit, sha: 'a' * 40)]
    result = Git::FsckResult.new(dangling: dangling)

    assert_equal(false, result.empty?)
  end

  test 'any_issues? returns false when all arrays are empty' do
    result = Git::FsckResult.new

    assert_equal(false, result.any_issues?)
  end

  test 'any_issues? returns true when missing is not empty' do
    missing = [Git::FsckObject.new(type: :blob, sha: 'b' * 40)]
    result = Git::FsckResult.new(missing: missing)

    assert(result.any_issues?)
  end

  test 'all_objects returns combined array' do
    obj1 = Git::FsckObject.new(type: :commit, sha: 'a' * 40)
    obj2 = Git::FsckObject.new(type: :blob, sha: 'b' * 40)
    obj3 = Git::FsckObject.new(type: :tree, sha: 'c' * 40)
    obj4 = Git::FsckObject.new(type: :tag, sha: 'd' * 40, message: 'badTimezone')

    result = Git::FsckResult.new(
      dangling: [obj1],
      missing: [obj2],
      unreachable: [obj3],
      warnings: [obj4]
    )

    all = result.all_objects
    assert_equal(4, all.size)
    assert_includes(all, obj1)
    assert_includes(all, obj2)
    assert_includes(all, obj3)
    assert_includes(all, obj4)
  end

  test 'count returns total number of objects' do
    result = Git::FsckResult.new(
      dangling: [Git::FsckObject.new(type: :commit, sha: 'a' * 40)],
      missing: [Git::FsckObject.new(type: :blob, sha: 'b' * 40)],
      unreachable: [],
      warnings: [
        Git::FsckObject.new(type: :commit, sha: 'c' * 40, message: 'msg1'),
        Git::FsckObject.new(type: :commit, sha: 'd' * 40, message: 'msg2')
      ]
    )

    assert_equal(4, result.count)
  end

  test 'to_h returns hash representation' do
    dangling = [Git::FsckObject.new(type: :commit, sha: 'a' * 40)]
    missing = [Git::FsckObject.new(type: :blob, sha: 'b' * 40)]

    result = Git::FsckResult.new(dangling: dangling, missing: missing)
    hash = result.to_h

    assert_instance_of(Hash, hash)
    assert_equal(dangling, hash[:dangling])
    assert_equal(missing, hash[:missing])
    assert_equal([], hash[:unreachable])
    assert_equal([], hash[:warnings])
    assert_equal([], hash[:root])
    assert_equal([], hash[:tagged])
  end

  test 'empty? returns true even when root and tagged have items' do
    root = [Git::FsckObject.new(type: :commit, sha: 'a' * 40)]
    tagged = [Git::FsckObject.new(type: :commit, sha: 'b' * 40, name: 'v1.0.0')]

    result = Git::FsckResult.new(root: root, tagged: tagged)

    # root and tagged are informational, not issues
    assert(result.empty?)
    assert_equal(false, result.any_issues?)
  end
end
