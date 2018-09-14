#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestDescribe < Test::Unit::TestCase

  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end

  def test_describe
    assert_equal'v2.8', @git.describe(nil, tags: true)
  end

  def test_describe_abbrev

    # Make sure we're not on the tag.
    @git.commit 'change', allow_empty: true

    assert_match /^v2\.8-1-g\h{7}$/, @git.describe(nil, tags: true),
        'git-describe should return the full describe if abbrev isn\'t provided'

    assert_match /^v2\.8-1-g\h{1,8}$/, @git.describe(nil, tags: true, abbrev: 1),
        'git-describe should use the minimum digits required for a unique object name.'

    assert_equal 'v2.8', @git.describe(nil, tags: true, abbrev: 0),
        'git-describe should just return the last tag if abbrev is 0'

  end

end
