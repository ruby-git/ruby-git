# frozen_string_literal: true

require 'test_helper'

class TestFsckObject < Test::Unit::TestCase
  def test_attributes
    obj = Git::FsckObject.new(type: :commit, oid: 'abc123', message: 'test message', name: 'HEAD~2')

    assert_equal(:commit, obj.type)
    assert_equal('abc123', obj.oid)
    assert_equal('test message', obj.message)
    assert_equal('HEAD~2', obj.name)
  end

  def test_message_defaults_to_nil
    obj = Git::FsckObject.new(type: :tree, oid: 'def456')

    assert_nil(obj.message)
  end

  def test_name_defaults_to_nil
    obj = Git::FsckObject.new(type: :tree, oid: 'def456')

    assert_nil(obj.name)
  end

  def test_to_s_returns_oid
    obj = Git::FsckObject.new(type: :blob, oid: 'abc123def456')

    assert_equal('abc123def456', obj.to_s)
  end
end
