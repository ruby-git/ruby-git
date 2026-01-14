# frozen_string_literal: true

require 'test_helper'

class TestArgsBuilder < Test::Unit::TestCase
  def test_boolean_negatable_with_true
    option_map = [
      { keys: [:dangling], flag: '--dangling', type: :boolean_negatable }
    ]
    opts = { dangling: true }

    result = Git::ArgsBuilder.build(opts, option_map)

    assert_equal(['--dangling'], result)
  end

  def test_boolean_negatable_with_false
    option_map = [
      { keys: [:dangling], flag: '--dangling', type: :boolean_negatable }
    ]
    opts = { dangling: false }

    result = Git::ArgsBuilder.build(opts, option_map)

    assert_equal(['--no-dangling'], result)
  end

  def test_boolean_negatable_with_nil
    option_map = [
      { keys: [:dangling], flag: '--dangling', type: :boolean_negatable }
    ]
    opts = { dangling: nil }

    result = Git::ArgsBuilder.build(opts, option_map)

    assert_equal([], result)
  end

  def test_boolean_negatable_when_omitted
    option_map = [
      { keys: [:dangling], flag: '--dangling', type: :boolean_negatable }
    ]
    opts = {}

    result = Git::ArgsBuilder.build(opts, option_map)

    assert_equal([], result)
  end
end
