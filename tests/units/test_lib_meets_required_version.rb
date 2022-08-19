#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

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
end
