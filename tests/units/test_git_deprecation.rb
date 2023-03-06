require 'test_helper'

class TestGitDeprecation < Test::Unit::TestCase
  test 'Git.deprecation should return an ActiveSupport::Deprecation' do
    assert(Git.deprecation.is_a?(ActiveSupport::Deprecation))
  end

  test 'Calling Git.deprecation more than once should return the same object' do
    assert_equal(Git.deprecation.object_id, Git.deprecation.object_id)
  end
end
