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

  def test_describe_first_parent

    # Set-up a merged branch with a newer tag on it
    main_branch = @git.current_branch
    @git.branch('first_parent').checkout
    @git.commit 'change', allow_empty: true
    @git.add_tag 'v2.8.1'
    @git.branches[main_branch].checkout
    @git.commit 'change', allow_empty: true
    @git.merge 'first_parent'
    @git.commit 'change', allow_empty: true

    # Display current state of test structure on console
    @git.chdir { puts `git --no-pager log --oneline --graph --decorate --all -n 10` }

    assert_equal 'v2.8.1', @git.describe(main_branch, tags: true, abbrev: 0),
        'git-describe should return the newer tag when first_parent not used.'

    assert_equal 'v2.8', @git.describe(main_branch, tags: true, abbrev: 0, first_parent: true),
        'git-describe should return the older tag when first_parent is used.'

  end

end
