# frozen_string_literal: true

require 'test_helper'

class TestLibMeetsRequiredVersion < Test::Unit::TestCase
  def test_with_supported_command_version
    lib = Git::Lib.new(nil, nil)
    # suppress deprecation warnings for this test
    Git::Deprecation.stubs(:warn)
    # Stub git_version so no real git binary is needed
    lib.stubs(:git_version).returns(Git::MINIMUM_GIT_VERSION)
    assert lib.meets_required_version?
  end

  def test_with_old_command_version
    lib = Git::Lib.new(nil, nil)
    # suppress deprecation warnings for this test
    Git::Deprecation.stubs(:warn)
    lib.stubs(:git_version).returns(Git::Version.new(1, 28, 0))
    assert !lib.meets_required_version?
  end
end
