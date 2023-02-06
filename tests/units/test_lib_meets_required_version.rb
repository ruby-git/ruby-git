#!/usr/bin/env ruby

require 'test_helper'

class TestLibMeetsRequiredVersion < Test::Unit::TestCase
  def test_with_supported_command_version
    lib = Git::Lib.new(nil, nil)
    major_version, minor_version = lib.required_command_version
    lib.define_singleton_method(:current_command_version) { [major_version, minor_version] }
    assert lib.meets_required_version?
  end

  def test_with_old_command_version
    lib = Git::Lib.new(nil, nil)
    major_version, minor_version = lib.required_command_version

    # Set the major version to be returned by #current_command_version to be an
    # earlier version than required
    major_version = major_version - 1

    lib.define_singleton_method(:current_command_version) { [major_version, minor_version] }
    assert !lib.meets_required_version?
  end

  def test_parse_version
    lib = Git::Lib.new(nil, nil)

    versions_to_test = [
      { version_string: 'git version 2.1', expected_result: [2, 1, 0] },
      { version_string: 'git version 2.28.4', expected_result: [2, 28, 4] },
      { version_string: 'git version 2.32.GIT', expected_result: [2, 32, 0] },
    ]

    lib.instance_variable_set(:@next_version_index, 0)

    lib.define_singleton_method(:command) do |cmd, *opts, &block|
      raise ArgumentError unless cmd == 'version'
      versions_to_test[@next_version_index][:version_string].tap { @next_version_index += 1 }
    end

    lib.define_singleton_method(:next_version_index) { @next_version_index }

    expected_version = versions_to_test[lib.next_version_index][:expected_result]
    actual_version = lib.current_command_version
    assert_equal(expected_version, actual_version)

    expected_version = versions_to_test[lib.next_version_index][:expected_result]
    actual_version = lib.current_command_version
    assert_equal(expected_version, actual_version)
  end
end
