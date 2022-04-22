require 'test/unit'

# Tests for the Git::GitAltURI class
#
class TestGitAltURI < Test::Unit::TestCase
  def test_new
    uri = Git::GitAltURI.new(user: 'james', host: 'github.com', path: 'ruby-git/ruby-git.git')
    actual_attributes = uri.to_hash.delete_if { |_key, value| value.nil? }
    expected_attributes = {
      scheme: 'git-alt',
      user: 'james',
      host: 'github.com',
      path: '/ruby-git/ruby-git.git'
    }
    assert_equal(expected_attributes, actual_attributes)
  end

  def test_to_s
    uri = Git::GitAltURI.new(user: 'james', host: 'github.com', path: 'ruby-git/ruby-git.git')
    assert_equal('james@github.com:ruby-git/ruby-git.git', uri.to_s)
  end

  def test_to_s_with_nil_user
    uri = Git::GitAltURI.new(user: nil, host: 'github.com', path: 'ruby-git/ruby-git.git')
    assert_equal('github.com:ruby-git/ruby-git.git', uri.to_s)
  end
end
